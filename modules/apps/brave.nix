# ../../modules/apps/brave.nix
{ config, lib, ... }:

{
  options.myApps.brave.enable =
    lib.mkEnableOption "Brave Browser";

  config = lib.mkIf config.myApps.brave.enable {

    # ----------------------
    # Browser
    # ----------------------
    programs.brave = {
      enable = true;

      # Keep Brave's profile in the normal XDG location:
      # ~/.config/BraveSoftware/Brave-Browser

      extensions = [
        # SponsorBlock
        "mnjggcdmjocbbbhaepdhchncahnbgone"

        # Keepa
        "neebplgakaahbhdphmkckjjcegoiijjo"

        # Proton Pass
        "ghmbeldphafepmbegfdlkpapadhbakde"

        # Print Edit WE
        "olnblpmehglpcallpnbgmikjblmkopia"

        # Video DownloadHelper
        "lmjnegcaeklhafolokijcfjliaokphfk"

        # Consent-O-Matic
        "mdjildafknihdffpkfmmpnpoiajfjnjd"
      ];
    };

    # ----------------------
    # Brave / Chromium policies
    # ----------------------
#    programs.chromium = {
#      enable = true;
#
#      extraOpts = {
#        # Updates / background behaviour
#        BackgroundModeEnabled = false;
#
#        # Default browser
#        DefaultBrowserSettingEnabled = false;
#
#        # Autofill
#        AutofillAddressEnabled = false;
#        AutofillCreditCardEnabled = false;
#
#        # Passwords
#        PasswordManagerEnabled = false;
#
#        # Privacy
#        MetricsReportingEnabled = false;
#        SafeBrowsingExtendedReportingEnabled = false;
#
#        # Suggestions / promotions
#        PromotionsEnabled = false;
#
#        # Brave-specific
#        BraveRewardsDisabled = true;
#        BraveWalletDisabled = true;
#        TorDisabled = true;
#        BraveWebDiscoveryEnabled = false;
#        BraveP3AEnabled = false;
#        BraveStatsPingEnabled = 0;
#
#        # Permissions
#        DefaultGeolocationSetting = 2;
#        DefaultNotificationsSetting = 2;
#        DefaultSensorsSetting = 2;
#        DefaultSerialGuardSetting = 2;
#      };
#    };
  };
}
