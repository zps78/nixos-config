# ../../modules/apps-user/brave.nix
{ config, lib, ... }:

{
  options.myApps.brave.enable =
    lib.mkEnableOption "Brave Browser";

  config = lib.mkIf config.myApps.brave.enable {
    programs.brave = {
      enable = true;

      # Chrome Web Store IDs. Firefox equivalents live in
      # ./browser-extensions.nix - keep this list roughly in sync.
      # (No uBlock: Brave has built-in adblock. No real torrent-control
      # equivalent - Remote Torrent Adder below is the closest fit, but
      # it intercepts matching page links rather than registering as a
      # magnet: protocol handler, and needs its own WebUI host/port/
      # credentials entered in its Options page - that's extension
      # storage, not something this file or a policy can set.)
      extensions = [
        "mnjggcdmjocbbbhaepdhchncahnbgone"  # SponsorBlock
        "neebplgakaahbhdphmkckjjcegoiijjo"  # Keepa
        "ghmbeldphafepmbegfdlkpapadhbakde"  # Proton Pass
        "olnblpmehglpcallpnbgmikjblmkopia"  # Print Edit WE
        "lmjnegcaeklhafolokijcfjliaokphfk"  # Video DownloadHelper
        "mdjildafknihdffpkfmmpnpoiajfjnjd"  # Consent-O-Matic
        "oabphaconndgibllomdcjbfdghcmenci"  # Remote Torrent Adder
      ];
    };
  };
}
