# ../../modules/desktop/stream-apps/lib.nix
#
# Shared building blocks for the stream-app modules (not a module itself):
#   let sa = import ./lib.nix { inherit config lib pkgs; }; in ...
{ config, lib, pkgs }:

let
  cfg = config.myDesktop.streamApps;
  user = config.myDesktop.sessionUser;
  uid = toString config.users.users.${user}.uid;
in
rec {
  inherit cfg user uid;

  # Which app the current Sunshine session is - the session control and
  # the disconnect/reconnect watcher treat each app by its own rules.
  stateFile = "/run/user/${uid}/sunshine-app";

  # A wlroots compositor (cage, labwc) runs this as its one client: every
  # output except the dummy plug off (Sunshine captures "monitor 0" = the
  # first plane with a framebuffer, so a lit console monitor would be
  # captured instead), the dummy plug in the stream mode - a mode from its
  # EDID list (NVIDIA rejects a custom mode, "failed to apply
  # configuration"). Logs the before/after state and the capability sets
  # to the journal. Then the program full-screen.
  kioskLauncher = name: program: pkgs.writeShellScript name ''
    r=${pkgs.wlr-randr}/bin/wlr-randr
    echo "== outputs at start"; $r
    for o in $($r --json | ${pkgs.jq}/bin/jq -r '.[].name'); do
      [ "$o" = ${cfg.output} ] || $r --output "$o" --off || echo "could not turn off $o"
    done
    $r --output ${cfg.output} --mode ${toString cfg.width}x${toString cfg.height}@${toString cfg.refresh} \
      || $r --output ${cfg.output} --mode ${toString cfg.width}x${toString cfg.height} \
      || echo "could not set ${toString cfg.width}x${toString cfg.height} on ${cfg.output}"
    echo "== outputs after"; $r
    grep -E '^Cap(Inh|Prm|Eff|Amb)' /proc/self/status | tr '\n' ' '; echo
    exec ${program}
  '';

  # A real login session (pam_systemd) for the session user on its own VT -
  # same pattern as NixOS's cage kiosk module. chvt makes the VT the
  # foreground one, so logind marks the session active and the compositor
  # can take DRM master; on exit the screen goes back to the tty1 console.
  # (The PAM service needs security.pam.services.<pamName>.startSession.)
  sessionUnit = { description, pamName, execStart, environment ? { }, serviceConfig ? { } }: {
    inherit description;
    after = [ "systemd-user-sessions.service" "systemd-logind.service" "user@${uid}.service" ];
    wants = [ "user@${uid}.service" ];

    # Services get a minimal PATH; session scripts call programs by name.
    # Same order as a login shell: setcap/suid wrappers, the user's
    # home-manager profile, then system.
    path = [ "/run/wrappers" "/etc/profiles/per-user/${user}" "/run/current-system/sw" ];
    environment = {
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_CLASS = "user";
    } // environment;

    serviceConfig = {
      User = user;
      PAMName = pamName;
      WorkingDirectory = "~";

      TTYPath = "/dev/tty${toString cfg.vt}";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
      StandardInput = "tty-fail";
      StandardOutput = "journal";
      StandardError = "journal";
      UtmpIdentifier = "tty${toString cfg.vt}";
      UtmpMode = "user";

      ExecStartPre = "+${pkgs.kbd}/bin/chvt ${toString cfg.vt}";
      ExecStart = execStart;
      ExecStopPost = "+${pkgs.kbd}/bin/chvt 1";
      Restart = "no";
    } // serviceConfig;
  };

  # Moonlight tile in the house style (2026-11-23, after Zen's): 600x800,
  # dark gradient, the symbol in a 280x280 box at +160+190, the label in
  # Inter ~650 / 52 px on baseline y=659. logoSvg is rendered at logoSize
  # and placed at logoPos - for SVGs with a margin, render a bit larger and
  # shift up-left so the visible symbol fills the box.
  mkTile = { name, label, logoSvg, logoSize ? 280, logoPos ? "+160+190", fill ? null }:
    pkgs.runCommand "${name}-boxart.png" {
      nativeBuildInputs = [ pkgs.librsvg pkgs.imagemagick ];
      FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [ pkgs.inter ]; };
    } ''
      export HOME=$TMPDIR
      ${if fill == null
        then "cp ${logoSvg} logo.svg"
        else "sed 's|<svg |<svg fill=\"${fill}\" |' ${logoSvg} > logo.svg"}
      rsvg-convert -w ${toString logoSize} -h ${toString logoSize} logo.svg -o logo.png
      cat > label.svg <<'EOF'
      <svg xmlns="http://www.w3.org/2000/svg" width="600" height="800"><text x="300" y="659" text-anchor="middle" font-family="Inter" font-weight="650" font-size="52" fill="#ffffff">${label}</text></svg>
      EOF
      rsvg-convert label.svg -o label.png
      magick -size 600x800 gradient:'#2a2833'-'#121117' \
        logo.png -geometry ${logoPos} -composite \
        label.png -composite \
        -depth 8 $out
    '';
}
