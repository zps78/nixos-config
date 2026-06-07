# ../../modules/shares/nfs/mounts/nfs-trading.nix
#
# NFS mount for trading share
#

{ config, lib, pkgs, ... }:

{
  options.myShares.nfs-trading.enable =
    lib.mkEnableOption "NAS trading share";

  config = lib.mkIf config.myShares.nfs-trading.enable {
    # Import modules
  #  imports = [
   #   ../nfs-client.nix
   # ];

    ############################################################
    # NFS mount: trading directory
    ############################################################

    fileSystems."/mnt/trading" = {
      # NFS export from NAS / server
      device = "192.168.1.5:/mnt/user/trading";
      # Use NFSv4 explicitly (recommended)
      fsType = "nfs4";

      options = [

      ########################################################
        # Systemd integration (CRITICAL for desktop stability)
        ########################################################

        "x-systemd.automount"           # mount on demand (prevents boot hangs)
        "x-systemd.idle-timeout=300"    # unmount after 5 min idle (optional but useful)
        "x-systemd.device-timeout=10s"

        "x-systemd.requires=network-online.target"
        "x-systemd.after=network-online.target"

        "_netdev"                       # wait for network
        "nofail"                        # do not fail boot if NAS is offline

        ########################################################
        # Performance / behavior tuning
        ########################################################

        "noatime"                       # avoids write overhead on access time updates
        "tcp"                           # TCP is correct for modern NFS (UDP is obsolete)

        ########################################################
        # Block sizes (good for large torrent files)
        ########################################################

        "rsize=1048576"
        "wsize=1048576"

        ########################################################
        # Stability tuning
        ########################################################

        "timeo=600"                     # very long timeout (good for unstable WiFi, bad for fast failure)
        "retrans=2"

        "async"                         # optional (safe for read-mostly usage)
      ];
    };
  };
}
