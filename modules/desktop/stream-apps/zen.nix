# ../../modules/desktop/stream-apps/zen.nix
#
# Stream app "Zen (VPN)": the Zen browser full-screen in cage on the dummy
# plug, inside a VPN-Confinement namespace (only the tunnel; kill switch).
# Same Sunshine/NVENC stream as Steam, so video plays at Moonlight quality.
# Short disconnect grace (idleStop) - little time for anyone to resume into
# a browser. The browser itself (private mode, policies): home/users/steam.nix.
{ config, lib, pkgs, ... }:

let
  sa = import ./lib.nix { inherit config lib pkgs; };
  inherit (sa) user uid;
  scfg = config.myDesktop.streamApps;
  cfg = scfg.zen;

  unit = "zen-vpn.service";
  launcher = sa.kioskLauncher "zen-vpn-launch" "/etc/profiles/per-user/${user}/bin/zen-beta";

  # Tile, 600x800 like the others: Zen's own vector logo + wordmark (from
  # the steam user's Zen package, so it follows Zen's branding) on the dark
  # gradient - the original the house style was measured from. omni.ja is a
  # non-standard zip - unzip reads it but complains, hence the checks
  # instead of its exit code.
  zenPkg = config.home-manager.users.${user}.programs.zen-browser.package;
  tile = pkgs.runCommand "zen-vpn-boxart.png" {
    nativeBuildInputs = [ pkgs.unzip pkgs.librsvg pkgs.imagemagick ];
  } ''
    for f in about-logo about-wordmark; do
      unzip -p ${zenPkg}/lib/zen-bin-*/browser/omni.ja chrome/browser/content/branding/$f.svg > $f.svg 2>/dev/null || true
      [ -s $f.svg ] || { echo "$f.svg not found in Zen's omni.ja"; exit 1; }
    done
    rsvg-convert -w 480 about-logo.svg -o logo.png
    rsvg-convert -w 320 about-wordmark.svg -o word.png
    magick -size 600x800 gradient:'#2a2833'-'#121117' \
      \( logo.png \) -gravity center -geometry +0-70 -composite \
      \( word.png \) -gravity center -geometry +0+240 -composite \
      -depth 8 $out
  '';
in
{
  options.myDesktop.streamApps.zen = {
    enable = lib.mkEnableOption "the Zen (VPN) stream app: the Zen browser in cage, inside a VPN namespace";
    idleStop = lib.mkOption {
      type = lib.types.str;
      default = "30s";
      description = "How long after a Moonlight disconnect Zen keeps running (short: it's a browser session).";
    };
    vpnNamespace = lib.mkOption {
      type = lib.types.str;
      default = "airvpn";
      description = "VPN-Confinement namespace Zen runs in (only the tunnel; kill switch).";
    };
  };

  config = lib.mkIf (scfg.enable && cfg.enable) {
    assertions = [
      { assertion = config.vpnNamespaces ? ${cfg.vpnNamespace};
        message = "myDesktop.streamApps.zen: VPN namespace '${cfg.vpnNamespace}' isn't defined (myServices.vpnTorrent)."; }
    ];

    myDesktop.streamApps.apps.zen = {
      title = "Zen (VPN)";
      order = 20;
      inherit unit tile;
      label = "Zen (VPN)";
      waitFor = ''-f "zen-beta|/zen "'';
      inherit (cfg) idleStop;
    };

    # Hardware video decode for Zen on the NVIDIA GPU (VA-API -> NVDEC).
    hardware.graphics.extraPackages = [ pkgs.nvidia-vaapi-driver ];

    security.pam.services.zen-vpn.startSession = true;

    systemd.services.zen-vpn = sa.sessionUnit {
      description = "Zen browser in cage, inside the ${cfg.vpnNamespace} VPN namespace (on demand, for Sunshine)";
      pamName = "zen-vpn";
      execStart = "${pkgs.cage}/bin/cage -d -s -- ${launcher}";
      environment = {
        XDG_RUNTIME_DIR = "/run/user/${uid}";                       # PipeWire (stream audio), session bus
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${uid}/bus";
        WLR_NO_HARDWARE_CURSORS = "1";                              # cursor drawn into the frame, so it's in the stream
        # Always composite into the primary plane - same reason as gamescope's
        # --force-composition: a full-screen Zen is otherwise scanned out
        # directly, the primary plane Sunshine's KMS capture reads stays empty
        # ("Couldn't get drm fb for plane [0]") and the stream is black.
        WLR_SCENE_DISABLE_DIRECT_SCANOUT = "1";
        MOZ_ENABLE_WAYLAND = "1";
        LIBVA_DRIVER_NAME = "nvidia";                               # VA-API video decode on the 4060 Ti
        NVD_BACKEND = "direct";
        MOZ_DISABLE_RDD_SANDBOX = "1";
      };
    } // {
      # Only the tunnel: DNS via the namespace's resolv.conf, host DNS cache
      # blocked, no route out if the tunnel is down.
      vpnConfinement = {
        enable = true;
        vpnNamespace = cfg.vpnNamespace;
      };
    };
  };
}
