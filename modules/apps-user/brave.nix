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
      # (No uBlock: Brave has built-in adblock. No torrent-control.)
      extensions = [
        "mnjggcdmjocbbbhaepdhchncahnbgone"  # SponsorBlock
        "neebplgakaahbhdphmkckjjcegoiijjo"  # Keepa
        "ghmbeldphafepmbegfdlkpapadhbakde"  # Proton Pass
        "olnblpmehglpcallpnbgmikjblmkopia"  # Print Edit WE
        "lmjnegcaeklhafolokijcfjliaokphfk"  # Video DownloadHelper
        "mdjildafknihdffpkfmmpnpoiajfjnjd"  # Consent-O-Matic
      ];
    };
  };
}
