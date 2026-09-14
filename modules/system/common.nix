# ../../modules/system/common.nix
{ pkgs, lib, ... }:

{
  ############################################################
  # Run generic (non-Nix-built) Linux binaries
  ############################################################
  #
  # NixOS has no /lib64/ld-linux-x86-64.so.2 or FHS lib layout by
  # default, so prebuilt binaries that editors/tools fetch for
  # themselves (Zed's auto-installed language servers, VS Code's
  # remote-server bits, rustup, etc.) fail with "cannot run dynamically
  # linked executable". nix-ld provides that loader plus a small
  # library set. Extend `libraries` if a future error names a missing
  # .so nixpkgs doesn't cover here.
  #
  # Triggered by: Zed's "package-version-server" language server.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
      curl
      icu
    ];
  };

  ############################################################
  # Populate /bin, /usr/bin, /sbin, /usr/sbin (ALL hosts)
  ############################################################
  #
  # Same class of problem as nix-ld above: NixOS has none of these at
  # their traditional FHS paths, which breaks third-party tooling that
  # hardcodes them (Valve's pressure-vessel container bootstrap for
  # Steam/Bottles/Lutris's Proton runtimes; AppImages; installer
  # scripts with a #!/bin/sh shebang). envfs is a tiny (~1MB) FUSE
  # mount that resolves /bin and /usr/bin lookups on demand from the
  # calling process's own PATH - negligible footprint, so just on
  # everywhere rather than tracked per-feature.
  services.envfs.enable = true;

  # envfs's own module stops at /bin and /usr/bin - NixOS has no /sbin
  # or /usr/sbin directory at all, and several pieces of the
  # pressure-vessel/umu-launcher stack (pv-adverb, pressure-vessel-wrap,
  # and critically CPython's ctypes.util.find_library, used by UMU's
  # Python tooling) call the literal absolute path /sbin/ldconfig -
  # bypassing PATH/envfs entirely, since that's not a PATH lookup.
  # Confirmed via `grep -rl sbin/ldconfig` across an actual pressure-
  # vessel runtime tree. Symlinking /sbin and /usr/sbin to /usr/bin
  # (the standard usrmerge collapse) lets those absolute-path lookups
  # fall through to the same envfs resolution as everything else.
  systemd.tmpfiles.rules = [
    "L+ /sbin - - - - /usr/bin"
    "L+ /usr/sbin - - - - /usr/bin"
  ];

  # Third layer of the same bug, confirmed by directly reproducing a
  # pressure-vessel launch with debug output captured to a file: NixOS
  # never generates an ld.so.cache anywhere (by design - Nix binaries
  # carry full RPATHs, so there's nothing to cache), but pressure-
  # vessel's capsule-capture-libs step hard-requires an openable
  # ld.so.cache at BOTH of these paths for its host-library probing and
  # aborts the whole container bootstrap if either is missing:
  #   ldconfig: Can't open cache file /etc/ld.so.cache: No such file...
  #   capsule-capture-libs: error: open "/var/cache/ldconfig/ld.so.cache"...
  # Generating a real (if NixOS-irrelevant) cache at both locations is
  # enough to satisfy the check.
  system.activationScripts.ldSoCacheForContainers = ''
    mkdir -p /var/cache/ldconfig
    ${pkgs.glibc.bin}/bin/ldconfig -C /etc/ld.so.cache
    ${pkgs.glibc.bin}/bin/ldconfig -C /var/cache/ldconfig/ld.so.cache
  '';

  ############################################################
  # Nix core system behavior (ALL hosts)
  ############################################################
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # NixOS's nix.gc module sets Persistent=true by default on the
  # generated timer: if a host is off during its scheduled weekly
  # window, GC fires immediately on the very next boot instead of
  # waiting for the next weekly slot - a bad moment for it, competing
  # for disk I/O right as a user starts doing things. Confirmed doing
  # exactly this on krieger (timer's own LAST-fire timestamp was 6
  # seconds after boot) while a game install was starting, deleting
  # several old bottles/wine store paths at the same time. Waiting for
  # the next real weekly slot instead avoids that ambush.
  systemd.timers.nix-gc.timerConfig.Persistent = lib.mkForce false;

  ############################################################
  # Allow redistributable firmware (Wi-Fi, GPU, CPU microcode, etc.)
  ############################################################
  hardware.enableRedistributableFirmware = true;

  ############################################################
  # Base system utilities (safe everywhere)
  ############################################################
  programs.git.enable = true;
  services.fwupd.enable = true;
}
