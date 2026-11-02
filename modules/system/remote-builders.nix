# ../../modules/system/remote-builders.nix
#
# Offload heavy/uncached local builds (e.g. bambu-studio's
# withNvidiaGLWorkaround override - see modules/apps-user/bambu-studio.nix)
# to krieger (128GB RAM, 5950X) instead of OOMing on a weaker host like
# kepler. krieger has to actually be awake and reachable for this to do
# anything - it's woken manually (WoL), not kept running 24/7 - so this is
# a "use it when it's up" optimization, not a hard dependency: if krieger
# is unreachable, nix just falls back to building locally as it always did.
#
# Connects as bb (krieger's primaryUser, see hosts/krieger/configuration.nix
# ssh.authorizedKeys) using each client's own <hostname>-fleet-key, the same
# per-host outbound identity already used for admin SSH access (see
# home/users/zp.nix and secrets/secrets.nix). Building an input-addressed
# derivation (the default, i.e. almost everything in nixpkgs) over SSH does
# require the connecting user to be a trusted-user on the machine doing the
# build - confirmed the hard way ("you are not privileged to build
# input-addressed derivations") - so the server-side half below grants bb
# that on krieger specifically, scoped by hostname so it never applies
# anywhere else even though this file is imported on every host.
{ config, lib, ... }:

{
  options.myFeatures.remoteBuilder.enable =
    lib.mkEnableOption "use krieger as a distributed-build machine";

  config = lib.mkMerge [
    # Client side: hosts that offload builds to krieger.
    (lib.mkIf config.myFeatures.remoteBuilder.enable {
      nix.distributedBuilds = true;
      nix.settings.builders-use-substitutes = true;

      nix.buildMachines = [{
        hostName = "krieger";
        system = "x86_64-linux";
        sshUser = "bb";
        sshKey = "/run/agenix/${config.networking.hostName}-fleet-key";
        maxJobs = 16;
        speedFactor = 2;
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" ];
        # base64 -w0 of krieger's /etc/ssh/ssh_host_ed25519_key.pub - lets
        # root connect without an interactive known-hosts prompt on first
        # use. Re-derive this if krieger's host key ever changes.
        publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUVNaVk5UE5ZaEpHOU1lZW9FbEdHVHBxaVgrNFk1Q3RIUFNKSjNUUkV4VEg=";
      }];
    })

    # Server side: krieger itself, trusting bb to submit builds.
    (lib.mkIf (config.networking.hostName == "krieger") {
      nix.settings.trusted-users = [ "bb" ];
    })
  ];
}
