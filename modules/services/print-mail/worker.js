// Cloudflare Email Worker "print-mail" for print@printer.jpc.onl.
// Not deployed from this repo: paste it into the dashboard (Workers ->
// print-mail -> Edit code). See modules/services/print-mail.nix.
//
// Variables (Settings -> Variables and Secrets):
//   ALLOWED_SENDERS          text    comma-separated addresses
//   HOOK_URL                 text    https://print-hook.jpc.onl/print
//   HOOK_SECRET              secret  same value as secrets/print-mail-secret.age
//   CF_ACCESS_CLIENT_ID      secret  Access service token "print-mail"
//   CF_ACCESS_CLIENT_SECRET  secret  "
const MAX_BYTES = 30 * 1024 * 1024;

function address(value) {
  const v = (value || "").toLowerCase();
  const m = v.match(/<([^>]+)>/);
  return (m ? m[1] : v).trim();
}

export default {
  async email(message, env, ctx) {
    const allowed = env.ALLOWED_SENDERS.toLowerCase().split(",").map((s) => s.trim()).filter(Boolean);
    const envFrom = address(message.from);
    const hdrFrom = address(message.headers.get("from"));
    if (!allowed.includes(envFrom) || !allowed.includes(hdrFrom)) {
      console.log(`rejected sender: envelope=${envFrom} header=${hdrFrom}`);
      message.setReject("This address only accepts mail from authorised senders.");
      return;
    }
    if (message.rawSize > MAX_BYTES) {
      message.setReject("Message too large to print (limit 30 MB).");
      return;
    }

    const raw = await new Response(message.raw).arrayBuffer();
    let res;
    try {
      res = await fetch(env.HOOK_URL, {
        method: "POST",
        headers: {
          "Content-Type": "message/rfc822",
          "X-Print-Secret": env.HOOK_SECRET,
          "CF-Access-Client-Id": env.CF_ACCESS_CLIENT_ID,
          "CF-Access-Client-Secret": env.CF_ACCESS_CLIENT_SECRET,
        },
        body: raw,
      });
    } catch (e) {
      console.log(`hook unreachable: ${e}`);
      message.setReject("The printer is unreachable right now. Please try again later.");
      return;
    }
    const text = (await res.text()).slice(0, 400);
    console.log(`hook ${res.status}: ${text.split("\n")[0]}`);
    if (res.status === 422) message.setReject(text);
    else if (!res.ok) message.setReject(`Printing failed (${res.status}). Please try again later.`);
  },
};
