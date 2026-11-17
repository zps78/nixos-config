# ../../modules/system/remote-builders.nix
#
# Offload heavy/uncached local builds (e.g. bambu-studio's
# withNvidiaGLWorkaround override - see modules/apps-user/bambu-studio.nix)
# to the fleet's build machine instead of OOMing on a weaker host like
# kepler. Not a hard dependency: if the builder is unreachable, nix falls
# back to building locally as it always did.
#
# The builder is karma (5950X), the always-on NAS on krieger's old
# internals - it took over this role from krieger (woken by WoL, often
# off) on 2026-11-17. It runs as "karma-n5" until the phase-6 cutover;
# then only `builder.host` below changes to "karma" (same machine, same
# SSH host key).
#
# Reached by its Tailscale (MagicDNS) name: the LAN firewall keeps port 22
# closed by fleet design. Connects as the builder's primaryUser (dh on
# karma, see hosts/karma/configuration.nix ssh.authorizedKeys) using each
# client's own <hostname>-fleet-key, the same per-host outbound identity
# used for admin SSH (see home/users/zp.nix and secrets/secrets.nix).
# Building an input-addressed derivation (almost everything in nixpkgs)
# over SSH requires the connecting user to be a trusted-user on the
# builder - confirmed the hard way ("you are not privileged to build
# input-addressed derivations") - so the server-side half below grants
# that on the builder only, scoped by hostname so it never applies
# anywhere else even though this file is imported on every host.
{ config, lib, ... }:

let
  builder = {
    host = "karma-n5";   # phase 6: "karma"
    user = "dh";
    # base64 -w0 of the builder's /etc/ssh/ssh_host_ed25519_key.pub - lets
    # root connect without an interactive known-hosts prompt on first use.
    # Same key as karma-host in secrets/secrets.nix; re-derive if it changes.
    publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUJCNzJoNGcwZHlRZDdodHI1cEtITyswZVlJUzRaRmc0eDlGanhERDBMdGs=";
  };
in
{
  options.myFeatures.remoteBuilder.enable =
    lib.mkEnableOption "use the fleet build machine (karma) for distributed builds";

  config = lib.mkMerge [
    # Client side: hosts that offload builds to the builder.
    (lib.mkIf config.myFeatures.remoteBuilder.enable {
      nix.distributedBuilds = true;
      nix.settings.builders-use-substitutes = true;

      nix.buildMachines = [{
        hostName = builder.host;
        system = "x86_64-linux";
        sshUser = builder.user;
        sshKey = "/run/agenix/${config.networking.hostName}-fleet-key";
        maxJobs = 16;
        speedFactor = 2;
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" ];
        inherit (builder) publicHostKey;
      }];
    })

    # Server side: the builder itself, trusting its user to submit builds.
    (lib.mkIf (config.networking.hostName == builder.host) {
      nix.settings.trusted-users = [ builder.user ];
    })
  ];
}
