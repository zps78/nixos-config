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

in
{
  "kuro-fleet-key.age".publicKeys = [ zp-personal kuro-host ];
  "krugerrand-fleet-key.age".publicKeys = [ zp-personal krugerrand-host ];
}
