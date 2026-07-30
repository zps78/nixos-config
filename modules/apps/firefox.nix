# ../../modules/apps/firefox.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.firefox.enable =
    lib.mkEnableOption "Firefox";

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf config.myApps.firefox.enable {
    programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
    languagePacks = [ "en-US" "pt-PT" ];

    policies = {
      # Updates & Background Services
      AppAutoUpdate                 = false;
      BackgroundAppUpdate           = false;

      # Feature Disabling
      DisableBuiltinPDFViewer       = true;
      DisableFeedbackCommands       = true;
      DisableFirefoxStudies         = true;
      DisableFirefoxAccounts        = true;
      DisableFirefoxScreenshots     = true;
      DisableForgetButton           = true;
      DisableMasterPasswordCreation = true;
      DisableProfileImport          = true;
      DisableProfileRefresh         = true;
      DisableSetDesktopBackground   = true;
      DisablePocket                 = true;
      DisableTelemetry              = true;
      DisableFormHistory            = true;
      DisablePasswordReveal         = false;
      PasswordManagerEnabled        = false;

      UserMessaging = {
        ExtensionRecommendations    = false;
        FeatureRecommendations      = false;
        UrlbarInterventions         = false;
        SkipOnboarding              = true;
        MoreFromMozilla             = false;
        FirefoxLabs                 = true;
      };
      FirefoxSuggest = {
        WebSuggestions              = false;
        SponsoredSuggestions        = false;
        ImproveSuggest              = false;
        Locked                      = true;
      };
      FirefoxHome = {
        Search                      = true;
        TopSites                    = true;
        SponsoredTopSites           = false;
        Highlights                  = false;
        Pocket                      = false;
        Stories                     = false;
        SponsoredPocket             = false;
        SponsoredStories            = false;
        Snippets                    = false;
        Locked                      = false;
      };
      EnableTrackingProtection = {
        Value                       = true;
        Locked                      = false;
        Cryptomining                = true;
        Fingerprinting              = true;
        EmailTracking               = true;
        SuspectedFingerprinting     = true;
        BaselineExceptions          = true;
        ConvenienceExceptions       = true;
      };
      # Access Restrictions
      BlockAboutConfig              = false;
      BlockAboutProfiles            = true;
      BlockAboutSupport             = false;

      # UI and Behavior
      DisplayMenuBar                = "never";
      DontCheckDefaultBrowser       = true;
      HardwareAcceleration          = false;
      OfferToSaveLogins             = false;
      DefaultDownloadDirectory      = "${config.home.homeDirectory}/Downloads";

      # Extensions
      ExtensionSettings = let
        moz = short: "https://addons.mozilla.org/firefox/downloads/latest/${short}/latest.xpi";
        in {
          "*".installation_mode = "allowed";

          "uBlock0@raymondhill.net" = {
            install_url       = moz "ublock-origin";
            installation_mode = "force_installed";
          };

          "sponsorBlocker@ajay.app" = {
            install_url       = moz "sponsorblock";
            installation_mode = "force_installed";
          };

          "amptra@keepa.com" = {
            install_url       = moz "keepa";
            installation_mode = "force_installed";
          };

          "78272b6fa58f4a1abaac99321d503a20@proton.me" = {
            install_url       = moz "proton-pass";
            installation_mode = "force_installed";
          };

          "printedit-we@DW-dev" = {
            install_url       = moz "print-edit-we";
            installation_mode = "force_installed";
          };

          "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}" = {
            install_url       = moz "video-downloadhelper";
            installation_mode = "force_installed";
          };

          "gdpr@cavi.au.dk" = {
            install_url       = moz "consent-o-matic";
            installation_mode = "force_installed";
          };

          "{e6e36c9a-8323-446c-b720-a176017e38ff}" = {
            install_url       = moz "torrent-control";
            installation_mode = "force_installed";
          };
        };
      };
    };
  };
}