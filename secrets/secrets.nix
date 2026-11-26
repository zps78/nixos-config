# ../../secrets/secrets.nix
#
# agenix recipient manifest. Lists, per encrypted .age file, who can
# decrypt it: the target host's own SSH host key (so it decrypts
# automatically at activation, no human involved) plus zp's personal
# key (so secrets can be viewed/re-encrypted from kuro without needing
# to SSH into the target host itself).
#
# Regenerate/rotate a secret with the agenix CLI, e.g.:
#   nix run github:ryantm/agenix -- -e kuro-fleet-key.age
#
# Host keys: ssh-keyscan <host> or cat /etc/ssh/ssh_host_ed25519_key.pub
# on the host itself.

let
  zp-personal =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIxGQlgxc1CfXrVcUU1LkJW6Wy8iSPicINreokDT4NYs";

  kuro-host =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINlcP3tG5CnreduapzH9Oh5O2Yo+FM+t7tJU3gneIF79";

  krugerrand-host =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOYeT9OzYyi14AVhZrs4b6hXjxi/FBPDb4nSK0lgI8ah";

  kepler-host =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHzwlSF4o8N4UqASKAJUbAW8ZKtAFr1POrzKuUQWYS8t";

  kimi-host =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFQ3asT1lYai02B7wvOGaGUugjYU4dTDF4nAXzDN+XQe";

  # The new NAS (hosts/kraken), generated on its first boot 2026-11-17
  # (then named karma-n5; same machine, same key). The Unraid karma never
  # had an agenix key.
  kraken-host =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBB72h4g0dyQd7htr5pKHO+0eYIS4ZFg4x9FjxDD0Ltk";

in
{
  "kuro-fleet-key.age".publicKeys = [ zp-personal kuro-host ];
  "krugerrand-fleet-key.age".publicKeys = [ zp-personal krugerrand-host ];

  # kepler/kimi previously had no outbound fleet SSH identity at all
  # (leaf-only targets) - added so they can reach kraken as a
  # distributed-build client (see modules/system/remote-builders.nix).
  "kepler-fleet-key.age".publicKeys = [ zp-personal kepler-host ];
  "kimi-fleet-key.age".publicKeys = [ zp-personal kimi-host ];

  # Home router MAC, used by modules/networking/tailscale.nix to detect
  # the home LAN. Kept out of the public repo because a router MAC is
  # often the Wi-Fi BSSID (or one off), which Wi-Fi location databases
  # map to a physical address. Every Tailscale host needs it.
  # zp's login/sudo password, as a yescrypt hash (users.users.zp.
  # hashedPasswordFile) - one password for zp on every host that uses it.
  # Create/change it from secrets/:
  #   mkpasswd -m yescrypt | nix run github:ryantm/agenix -- -e zp-password.age
  "zp-password.age".publicKeys =
    [ zp-personal kuro-host krugerrand-host kimi-host kraken-host ];

  # ntfy.sh topic for alerts (ZED, smartd, failed units - see
  # modules/services/alerts.nix). The topic name is the only protection on
  # ntfy.sh (whoever knows it can read and post), so it's random and kept
  # out of the public repo. Read it with:
  #   nix run github:ryantm/agenix -- -d ntfy-topic.age -i ~/.ssh/id_ed25519
  "ntfy-topic.age".publicKeys = [ zp-personal kraken-host ];

  # kraken's own AirVPN device: its WireGuard config (wg-quick format, from
  # the AirVPN config generator) for modules/services/vpn-torrent.nix.
  # Encrypt straight from the downloaded file, from secrets/:
  #   nix run github:ryantm/agenix -- -e airvpn-wg.conf.age < ~/Downloads/<file>.conf
  "airvpn-wg.conf.age".publicKeys = [ zp-personal kraken-host ];

  # kraken Homepage's widget credentials, as an environment file
  # (HOMEPAGE_VAR_<NAME>=value lines, referenced as {{HOMEPAGE_VAR_<NAME>}}
  # in the Homepage config). Currently: QBIT_USER, QBIT_PASSWORD,
  # PAPERLESS_KEY, HC_PROJECT (healthchecks.io project id), HC_KEY (its
  # read-only API key).
  "homepage-env.age".publicKeys = [ zp-personal kraken-host ];

  # kraken's SMB password for the scanner account (myServices.samba user
  # "scanner" - the Brother ADS-4300N scans into Paperless's consume
  # folder). One line, the password only.
  "samba-scanner-password.age".publicKeys = [ zp-personal kraken-host ];

  # kraken's qBittorrent WebUI password as qBittorrent's PBKDF2 value, one
  # line: @ByteArray(<base64 salt>:<base64 hash>) (myServices.vpnTorrent).
  "qbittorrent-webui.age".publicKeys = [ zp-personal kraken-host ];

  # kraken's healthchecks.io ping URL (myServices.alerts.heartbeatUrlFile):
  # the external down-check. One line, https://hc-ping.com/<uuid>.
  "heartbeat-url.age".publicKeys = [ zp-personal kraken-host ];

  # kraken's healthchecks.io project ping key (myServices.alerts.
  # healthchecks.pingKeyFile): "job finished" pings per check slug. One line.
  "healthchecks-ping-key.age".publicKeys = [ zp-personal kraken-host ];

  # kraken's FileBrowser Quantum admin password (myServices.
  # filebrowserQuantum, user zp), one line, at least 12 characters.
  "filebrowser-admin.age".publicKeys = [ zp-personal kraken-host ];

  # kraken's Cloudflare tunnel token (myServices.cloudflareTunnel), as an
  # environment file: TUNNEL_TOKEN=<token>
  "cloudflare-tunnel.age".publicKeys = [ zp-personal kraken-host ];

  "home-gateway-mac.age".publicKeys =
    [ zp-personal kuro-host krugerrand-host kepler-host kimi-host kraken-host ];
}
