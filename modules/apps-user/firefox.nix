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

          # Stop the "translate this page?" popup from offering itself
          # unprompted - the icon stays in the URL bar for manual use.
          "browser.translations.automaticallyPopup" = false;
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

        # Blocks Google's "Sign in with Google" One Tap widget SDK -
        # the unprompted popup that shows up on unrelated sites (news
        # sites etc.) that embed it. Narrowly scoped to /gsi/* (the
        # widget's own path), so it doesn't touch the older/classic
        # Google OAuth redirect flow - only sites using this specific
        # SDK's button will also stop working, not Google sign-in
        # generally.
        WebsiteFilter = {
          Block = [ "https://accounts.google.com/gsi/*" ];
        };

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
