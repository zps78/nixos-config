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
# closed by fleet design. Connects as the builder's primaryUser (zp on
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
    user = "zp";
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
        # 8 jobs x 8 threads (cores, set on the builder below) = up to 64
        # compiler processes: still 2x the 5950X's 32 threads, so the CPU
        # stays saturated, without the 16 x 32 that OOM'd karma on
        # 2026-11-18 (C++ builds next to a HandBrake encode).
        maxJobs = 8;
        speedFactor = 2;
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" ];
        inherit (builder) publicHostKey;
      }];
    })

    # Server side: the builder itself, trusting its user to submit builds.
    (lib.mkIf (config.networking.hostName == builder.host) {
      # TRANSITION: "dh" too, until every client has been rebuilt once -
      # until then their /etc/nix/machines still connects as dh.
      nix.settings.trusted-users = [ builder.user "dh" ];

      # The builder is also the NAS/streaming box, so builds must never
      # starve its services. 2026-11-18: offloaded C++ builds (16 jobs, each
      # with all 32 threads) plus a HandBrake encode ran karma out of memory;
      # the OOM killer took the steam/admin session buses, PipeWire and
      # Sunshine. Now:
      nix.settings = {
        cores = 8;          # threads per build job
        max-jobs = 8;       # the builder's own (local) parallel builds
      };

      # All builds run inside nix-daemon's cgroup: cap that, so memory
      # pressure throttles builds first (MemoryHigh) and, at the hard
      # limit, the kernel kills a *build* - never a service or session.
      # Percent of physical RAM: 64 GB now, 128 GB after the RMA.
      systemd.services.nix-daemon.serviceConfig = {
        MemoryHigh = "60%";
        MemoryMax = "70%";
      };
    })
  ];
}
