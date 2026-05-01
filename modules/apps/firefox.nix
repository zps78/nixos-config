# ../../modules/apps/firefox.nix
{ config, pkgs, lib, ... }:

{
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

    EnableTrackingProtection      = true;

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
          updates_disabled  = true;
        };

        "sponsorBlocker@ajay.app" = {
          install_url       = moz "sponsorblock";
          installation_mode = "force_installed";
          updates_disabled  = true;
        };

        "amptra@keepa.com" = {
          install_url       = moz "keepa";
          installation_mode = "force_installed";
          updates_disabled  = true;
        };

        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url       = moz "bitwarden-password-manager";
          installation_mode = "force_installed";
          updates_disabled  = true;
        };

        "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}" = {
          install_url       = moz "video-downloadhelper";
          installation_mode = "force_installed";
          updates_disabled  = true;
        };

        "gdpr@cavi.au.dk" = {
          install_url       = moz "consent-o-matic";
          installation_mode = "force_installed";
          updates_disabled  = true;
        };

        "{e6e36c9a-8323-446c-b720-a176017e38ff}" = {
          install_url       = moz "torrent-control";
          installation_mode = "force_installed";
          updates_disabled  = true;
        };
      };
    };
  };
}
