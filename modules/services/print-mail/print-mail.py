# print-mail: receives one raw email per POST (from the Cloudflare Email
# Worker, through the tunnel) and prints its attachments on the CUPS queue.
# Python stdlib only. One request at a time (LibreOffice must not run twice
# on the same profile), which is plenty for a home printer.
import email, email.policy, email.utils, hmac, json, os, re, shutil
import subprocess, sys, time, urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

PORT = int(os.environ["PM_PORT"])
QUEUE = os.environ["PM_QUEUE"]
ALLOWED = {a.strip().lower() for a in os.environ["PM_ALLOWED"].split(",") if a.strip()}
STATE = Path(os.environ["STATE_DIRECTORY"])
JOBS = STATE / "jobs"
KEEP_DAYS = int(os.environ.get("PM_KEEP_DAYS", "7"))
NTFY_SERVER = os.environ.get("PM_NTFY_SERVER", "")
HOST = os.environ.get("PM_HOST", "print-mail")
CREDS = Path(os.environ["CREDENTIALS_DIRECTORY"])
SECRET = (CREDS / "secret").read_text().strip().encode()
NTFY_TOPIC = (CREDS / "ntfy-topic").read_text().strip() if (CREDS / "ntfy-topic").exists() else ""
MAX_BYTES = 40 * 1024 * 1024

DIRECT = {".pdf", ".txt"}
IMAGES = {".jpg", ".jpeg", ".png", ".gif", ".tif", ".tiff", ".bmp"}
OFFICE = {".doc", ".docx", ".odt", ".rtf", ".xls", ".xlsx", ".ods",
          ".ppt", ".pptx", ".odp", ".pages", ".numbers", ".key"}
LOGO_BYTES = 50 * 1024   # inline images under this are signature logos

def log(*a):
    print(*a, file=sys.stderr, flush=True)

def ntfy(title, body, tags):
    if not (NTFY_SERVER and NTFY_TOPIC):
        return
    req = urllib.request.Request(f"{NTFY_SERVER}/{NTFY_TOPIC}", data=body.encode(),
                                 headers={"Title": f"{HOST}: {title}", "Tags": tags})
    try:
        urllib.request.urlopen(req, timeout=20).read()
    except Exception as e:
        log("ntfy failed:", e)

def safe_name(name, n):
    name = os.path.basename(name or "").strip() or f"attachment-{n}"
    name = re.sub(r"[^\w.\- ()]+", "_", name)[:120]
    return name if not name.startswith(".") else f"_{name}"

def to_pdf(src, outdir):
    home = STATE / "lo-home"
    home.mkdir(exist_ok=True)
    r = subprocess.run(["soffice", "--headless", "--norestore", "--nolockcheck",
                        "--convert-to", "pdf", "--outdir", str(outdir), str(src)],
                       env={**os.environ, "HOME": str(home)},
                       capture_output=True, text=True, timeout=180)
    pdf = outdir / (src.stem + ".pdf")
    if r.returncode != 0 or not pdf.exists():
        raise RuntimeError(f"conversion failed: {(r.stderr or r.stdout).strip()[:200]}")
    return pdf

def lp(path, title, image):
    cmd = ["lp", "-d", QUEUE, "-t", title, "-o", "media=A4", "-o", "sides=two-sided-long-edge"]
    if image:
        cmd += ["-o", "fit-to-page"]
    r = subprocess.run(cmd + [str(path)], capture_output=True, text=True, timeout=60)
    if r.returncode != 0:
        raise RuntimeError(f"lp: {r.stderr.strip()[:200]}")
    return r.stdout.strip()

def prune():
    cutoff = time.time() - KEEP_DAYS * 86400
    for d in JOBS.glob("*"):
        if d.is_dir() and d.stat().st_mtime < cutoff:
            shutil.rmtree(d, ignore_errors=True)

def handle(raw):
    msg = email.message_from_bytes(raw, policy=email.policy.default)
    senders = [a.lower() for _, a in email.utils.getaddresses(msg.get_all("from", []))]
    if len(senders) != 1 or senders[0] not in ALLOWED:
        return 403, f"sender not allowed: {senders}"
    sender = senders[0]
    subject = str(msg.get("subject", "")).strip() or "(no subject)"

    job = JOBS / f"{time.strftime('%Y%m%d-%H%M%S')}-{os.urandom(3).hex()}"
    job.mkdir(parents=True, exist_ok=True)
    (job / "message.eml").write_bytes(raw)

    printed, skipped = [], []
    n = 0
    for part in msg.walk():
        if part.is_multipart():
            continue
        fname = part.get_filename()
        if not fname:
            continue                      # body text / html: ignored by design
        n += 1
        name = safe_name(fname, n)
        data = part.get_payload(decode=True) or b""
        ext = Path(name).suffix.lower()
        if ext in IMAGES and part.get_content_disposition() != "attachment" and len(data) < LOGO_BYTES:
            continue                      # signature logo, silently skipped
        path = job / f"{n:02d}-{name}"
        path.write_bytes(data)
        try:
            if ext in DIRECT or ext in IMAGES:
                jid = lp(path, name, ext in IMAGES)
            elif ext in OFFICE:
                jid = lp(to_pdf(path, job), name, False)
            else:
                skipped.append(f"{name} (unsupported type)")
                continue
            printed.append(name)
            log(f"printed {name} for {sender}: {jid}")
        except Exception as e:
            skipped.append(f"{name} ({e})")
            log(f"failed {name} for {sender}: {e}")

    summary = "\n".join([f"From: {sender}", f"Subject: {subject}"]
                        + [f"printed: {p}" for p in printed]
                        + [f"skipped: {s}" for s in skipped])
    if not printed:
        ntfy("email print: nothing printed", summary, "printer,warning")
        why = "; ".join(skipped) if skipped else "no attachments"
        return 422, f"Nothing was printed ({why}). Supported: PDF, images, Word/Excel/PowerPoint/LibreOffice files, text."
    ntfy(f"printed {len(printed)} file(s)", summary, "printer")
    return 200, summary

class Handler(BaseHTTPRequestHandler):
    def reply(self, code, text):
        data = text.encode()
        self.send_response(code)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        if self.path != "/print":
            return self.reply(404, "not found")
        if not hmac.compare_digest(self.headers.get("X-Print-Secret", "").encode(), SECRET):
            log("rejected: bad secret")
            return self.reply(403, "forbidden")
        size = int(self.headers.get("Content-Length") or 0)
        if not 0 < size <= MAX_BYTES:
            return self.reply(413, "message too large")
        raw = self.rfile.read(size)
        try:
            code, text = handle(raw)
        except Exception as e:
            log("error:", repr(e))
            ntfy("email print failed", repr(e), "printer,x")
            code, text = 500, "internal error"
        finally:
            prune()
        log(f"{code}: {text.splitlines()[0] if text else ''}")
        self.reply(code, text)

    def do_GET(self):
        self.reply(200 if self.path == "/health" else 404, "ok" if self.path == "/health" else "not found")

JOBS.mkdir(parents=True, exist_ok=True)
prune()
HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
