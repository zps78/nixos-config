# ../../modules/hardware/wwan.nix
#
# WWAN for the ThinkPad X12 Detachable Gen 2 (Quectel EM160R-GL, PCI
# 1eac:100d, on the generic MHI PCI driver).
#
# On this unit's factory firmware the modem reports itself FCC-unlocked
# and connects with no unlock step - ModemManager never invokes the
# fcc-unlock script below (it decides no unlock is needed once the SIM
# reads ready, regardless of script content). It's kept as a correct
# safety net in case a firmware update ever flips that. (Lenovo's
# lenovo-wwan-unlock blob is deliberately not used: DPR_Fcc_unlock_service
# faults the MHI controller on this modem.)
#
# Unlock sequence and hardware notes (this is the exact model - ThinkPad
# X12 Detachable Gen 2, same 1eac:100d):
# https://github.com/harenber/em160r-gl-unlock
{ config, lib, pkgs, ... }:

let
  enabled = config.myHardware.wwan.enable;

  # Runs after modem init (including after resume), only if the modem
  # reports FCC-locked. $1 is the control port, passed by ModemManager.
  # fcc_enable's sense is inverted: 0 means the regulatory gate is OFF
  # (unlocked). Both AT commands via mbimcli's AT passthrough, per
  # harenber/em160r-gl-unlock - verified this parses fine as one
  # argument despite the embedded comma (mbimcli doesn't split naively
  # on it; tested directly against /dev/null, fails only at device-open,
  # never at argument-parse).
  fccUnlock = pkgs.writeShellScript "1eac:100d" ''
    set -e
    DEV="''${1:-/dev/wwan0mbim0}"
    mbimcli=${lib.getExe' pkgs.libmbim "mbimcli"}
    "$mbimcli" -d "$DEV" -p --quectel-set-command='AT+QCFG="fcc_enable",0'
    "$mbimcli" -d "$DEV" -p --quectel-set-command='AT+CFUN=1'
  '';

  # The modem can internally reset during s2idle. Reloading the MHI
  # driver makes ModemManager reprobe it and rerun init.
  em160Resume = pkgs.writeShellScript "em160-resume" ''
    ${lib.getExe' pkgs.systemd "systemctl"} stop ModemManager.service
    ${lib.getExe' pkgs.kmod "modprobe"} -r mhi_pci_generic
    sleep 1
    ${lib.getExe' pkgs.kmod "modprobe"} mhi_pci_generic
    sleep 2
    ${lib.getExe' pkgs.systemd "systemctl"} start ModemManager.service
  '';

  sleepTargets = [
    "suspend.target"
    "hibernate.target"
    "hybrid-sleep.target"
    "suspend-then-hibernate.target"
  ];
in
{
  options.myHardware.wwan.enable =
    lib.mkEnableOption "WWAN modem support";

  config = lib.mkMerge [
    {
      # WWAN disabled by default: keep mhi_pci_generic from binding to
      # the modem so it stays fully powered down, and don't run
      # ModemManager (NetworkManager pulls it in by default otherwise).
      boot.blacklistedKernelModules =
        lib.mkIf (!enabled) [ "mhi_pci_generic" ];
      networking.modemmanager.enable = enabled;
    }

    (lib.mkIf enabled {
      # Placed at /etc/ModemManager/fcc-unlock.d/1eac:100d. ModemManager
      # ships no script for this exact modem (only 1eac:1001/1004/1007).
      networking.modemmanager.fccUnlockScripts = [
        { id = "1eac:100d"; path = fccUnlock; }
      ];

      networking.networkmanager.ensureProfiles.profiles."Digi.mobil" = {
        connection = {
          id = "Digi.mobil";
          type = "gsm";
        };
        gsm.apn = "internet";
        ipv4.method = "auto";
        ipv6.method = "auto";
      };

      environment.systemPackages = [ pkgs.libmbim pkgs.pciutils ];

      # Quectel EM160R-GL: deactivate PCIe ASPM L1 substates and D3cold
      # so the modem doesn't get stuck during MHI power-state
      # transitions (L1.2 -> stuck).
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1eac", ATTR{device}=="0x100d", \
          ATTR{d3cold_allowed}="0", \
          RUN+="${lib.getExe' pkgs.pciutils "setpci"} -s %k CAP_EXP+10.w=0000:0003"
      '';

      # --test-low-power-suspend-resume is what Lenovo's suspend-fix
      # script inserts; required for keyboard/touchpad recovery after
      # sleep on this machine.
      systemd.services.ModemManager.serviceConfig.ExecStart = [
        ""
        "${pkgs.modemmanager}/sbin/ModemManager --test-low-power-suspend-resume --test-quick-suspend-resume"
      ];

      systemd.services.em160-resume = {
        description = "EM160R-GL MHI reinit after resume";
        after = sleepTargets;
        wantedBy = sleepTargets;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = em160Resume;
        };
      };
    })
  ];
}
