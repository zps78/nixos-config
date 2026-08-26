# ../../modules/hardware/wwan.nix
# https://github.com/harenber/em160r-gl-unlock
{ config, lib, pkgs, ... }:

let
  enabled = config.myHardware.wwan.enable;
in
{
  options.myHardware.wwan.enable =
    lib.mkEnableOption "WWAN modem support";

  config = {
    # WWAN disabled by default:
    # prevent mhi-pci-generic from binding to MHI devices.
    boot.blacklistedKernelModules = lib.mkIf (!enabled) [
      "mhi_pci_generic"
    ];

    # Only enable ModemManager when WWAN is enabled.
    networking.modemmanager.enable = enabled;

    # WWAN-specific tools.
    environment.systemPackages = lib.mkIf enabled [
      pkgs.libmbim
      pkgs.pciutils
    ];

    # Quectel EM160R-GL:
    # deactivate PCIe ASPM and D3cold.
    #
    # This prevents the modem from falling into L1.2 and subsequently
    # getting stuck during MHI power-state transitions.
    services.udev.extraRules = lib.mkIf enabled ''
      # Quectel EM160R-GL: deactivate ASPM and D3cold
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1eac", ATTR{device}=="0x100d", \
        ATTR{d3cold_allowed}="0", \
        RUN+="${pkgs.pciutils}/bin/setpci -s %k CAP_EXP+10.w=0000:0003"
    '';

    # ModemManager needs the low-power suspend/resume test flags
    # for this modem.
    systemd.services.ModemManager = lib.mkIf enabled {
      serviceConfig = {
        ExecStart = [
          ""
          "${pkgs.modemmanager}/sbin/ModemManager --test-low-power-suspend-resume --test-quick-suspend-resume"
        ];
      };
    };

    # Quectel EM160R-GL FCC unlock.
    #
    # fcc_enable=0 means FCC lock disabled on this modem.
    # ModemManager runs this hook after modem initialization,
    # including after suspend/resume.
    environment.etc."ModemManager/fcc-unlock.d/1eac:100d" =
      lib.mkIf enabled {
        mode = "0755";
        text = ''
          #!/bin/bash
          # Quectel EM160R-GL FCC unlock for Lenovo ThinkPad X12 Detachable Gen 2

          set -e

          DEV="''${1:-/dev/wwan0mbim0}"

          ${pkgs.libmbim}/bin/mbimcli -d "$DEV" -p \
            --quectel-set-command='AT+QCFG="fcc_enable",0' || exit 1

          ${pkgs.libmbim}/bin/mbimcli -d "$DEV" -p \
            --quectel-set-command='AT+CFUN=1' || exit 1

          exit 0
        '';
      };

    # Reinitialize the EM160R-GL after system resume.
    #
    # The modem can internally reset during s2idle/S3. Reloading the
    # MHI driver makes ModemManager probe the modem again and rerun
    # the FCC unlock hook.
    systemd.services.em160-resume = lib.mkIf enabled {
      description = "EM160R-GL MHI reinit after resume";

      after = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
        "suspend-then-hibernate.target"
      ];

      serviceConfig = {
        Type = "oneshot";

        ExecStart = pkgs.writeShellScript "em160-resume" ''
          ${pkgs.systemd}/bin/systemctl stop ModemManager.service
          ${pkgs.kmod}/bin/modprobe -r mhi_pci_generic
          sleep 1
          ${pkgs.kmod}/bin/modprobe mhi_pci_generic
          sleep 2
          ${pkgs.systemd}/bin/systemctl start ModemManager.service
        '';
      };

      wantedBy = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
        "suspend-then-hibernate.target"
      ];
    };
  };
}
