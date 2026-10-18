# ../../modules/apps-system/citizen-card.nix
#
# Portuguese Citizen Card (Cartao de Cidadao) eID: smart-card reader
# support (pcscd) plus AMA's official "Autenticacao.Gov" middleware, for
# signing documents and (optionally) authenticating on gov.pt sites.
#
# pkgs.autenticacao-gov-pt-bin repackages AMA's own Flatpak build of the
# middleware (GUI app "eidguiV2") - this is the real government software,
# not a reimplementation, and already depends on ccid/pcsclite.
#
# services.pcscd provides the PC/SC daemon that talks to the USB smart-card
# reader; enabling it already pulls in pkgs.ccid (generic USB CCID driver,
# covers essentially every consumer reader) and its udev rules, so no
# reader-specific driver is needed for a standard USB-C CCID reader.

{ config, lib, pkgs, ... }:

{
  options.myFeatures.citizen-card.enable =
    lib.mkEnableOption "Portuguese Citizen Card eID (smart-card reader + Autenticacao.Gov middleware)";

  config = lib.mkIf config.myFeatures.citizen-card.enable {
    services.pcscd.enable = true;
    environment.systemPackages = [ pkgs.autenticacao-gov-pt-bin ];
  };
}
