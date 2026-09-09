# ../../modules/apps-user/firefox.nix
{ config, inputs, pkgs, lib, ... }:

let
  firefoxAddons = pkgs.extend inputs.firefox-addons.overlays.default;
  browserExtensions =
    import ./browser-extensions.nix firefoxAddons.firefox-addons;
in
{
  options.myApps.firefox.enable =
    lib.mkEnableOption "Firefox";

  config = lib.mkIf config.myApps.firefox.enable {
    programs.firefox = {
      enable = true;
      configPath = ".mozilla/firefox";
      languagePacks = [ "en-US" "pt-PT" ];

      # Extensions: nix-managed via the firefox-addons overlay (pinned in
      # flake.lock), same set as zen-browser.nix.
      profiles.default = {
        isDefault = true;

        settings = {
          # Auto-enable nix-installed extensions.
          "extensions.autoDisableScopes" = 0;
        };

        extensions = {
          force = true;
          packages = browserExtensions;
        };
      };

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
          FirefoxLabs                 = false;
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
        HardwareAcceleration          = true;
        OfferToSaveLogins             = false;
        DefaultDownloadDirectory      = "${config.home.homeDirectory}/Downloads";
      };
    };
  };
}
