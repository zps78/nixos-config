# ../../modules/apps-user/zen-browser.nix
{ config, inputs, pkgs, lib, ... }:

let
  cfg = config.myApps.zen-browser;

  firefoxAddons = pkgs.extend inputs.firefox-addons.overlays.default;
  browserExtensions =
    import ./browser-extensions.nix firefoxAddons.firefox-addons;

  prefs = {
    # Extension installation
    "extensions.autoDisableScopes" = 0;

    # Navigation
    "browser.backspace_action" = 0;

    # Disable unwanted features
    "extensions.pocket.enabled" = false;

    # Stop the "translate this page?" popup from offering itself
    # unprompted - the icon stays in the URL bar for manual use.
    "browser.translations.automaticallyPopup" = false;

    # Passwords / form data
    "signon.rememberSignons" = false;
    "browser.formfill.enable" = false;

    # Telemetry / data collection
    "datareporting.healthreport.uploadEnabled" = false;
    "toolkit.telemetry.enabled" = false;

    # Studies / experiments
    "app.shield.optoutstudies.enabled" = false;
    "app.normandy.enabled" = false;
  };
in
{
  imports = [
    inputs.zen-browser.homeModules.default
  ];

  options.myApps.zen-browser.enable =
    lib.mkEnableOption "Zen Browser";

  config = lib.mkIf cfg.enable {
    programs.zen-browser = {
      enable = true;

      # ff2mpv extension -> mpv
      nativeMessagingHosts = [ pkgs.ff2mpv-rust ];

      # UI translations: English + European Portuguese.
      languagePacks = [ "en-US" "pt-PT" ];

      # Firefox enterprise policies (Zen honours the same policies.json).
      # Carried over from the old firefox.nix when Firefox was dropped.
      policies = {
        # Blocks Google's "Sign in with Google" One Tap widget SDK - the
        # unprompted popup on unrelated sites that embed it. Scoped to
        # /gsi/* (the widget's own path), so classic Google OAuth sign-in
        # still works; only sites using this specific SDK's button break.
        WebsiteFilter = {
          Block = [ "https://accounts.google.com/gsi/*" ];
        };

        # Updates come from nix - no in-app updater or background updates.
        AppAutoUpdate                 = false;
        BackgroundAppUpdate           = false;

        # Telemetry / studies / Mozilla account+sync off (the prefs below
        # cover some of this; the policies lock it all down).
        DisableTelemetry              = true;
        DisableFirefoxStudies         = true;
        DisableFirefoxAccounts        = true;
        DisableFeedbackCommands       = true;
        DisablePocket                 = true;

        # PDFs open in the desktop PDF app (home/mime.nix), not a tab.
        DisableBuiltinPDFViewer       = true;

        # Misc features not used.
        DisableFirefoxScreenshots     = true;
        DisableForgetButton           = true;
        DisableMasterPasswordCreation = true;
        DisableProfileImport          = true;
        DisableProfileRefresh         = true;
        DisableSetDesktopBackground   = true;
        DisableFormHistory            = true;
        PasswordManagerEnabled        = false;  # Proton Pass instead
        OfferToSaveLogins             = false;

        # No recommendation / onboarding / "what's new" nags.
        UserMessaging = {
          ExtensionRecommendations    = false;
          FeatureRecommendations      = false;
          UrlbarInterventions         = false;
          SkipOnboarding              = true;
          MoreFromMozilla             = false;
          FirefoxLabs                 = false;
        };

        # Address-bar suggestions from Mozilla's servers / sponsors off.
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

        # Stronger tracking protection: cryptominers, fingerprinters and
        # email trackers on top of the default lists. Not locked, so a
        # broken site can still be allowed from the shield icon.
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

        BlockAboutConfig              = false;
        BlockAboutProfiles            = true;
        BlockAboutSupport             = false;

        DisplayMenuBar                = "never";
        DontCheckDefaultBrowser       = true;
        HardwareAcceleration          = true;

        # Save downloads straight to ~/Downloads.
        DefaultDownloadDirectory      = "${config.home.homeDirectory}/Downloads";
        PromptForDownloadLocation     = false;
      };

      profiles.default = {
        settings = prefs;

        extensions.packages = browserExtensions;

        search = {
          force = true;
          default = "ddg";

          engines = {
            startpage = {
              name = "Startpage";
              urls = [
                {
                  template =
                    "https://www.startpage.com/sp/search?query={searchTerms}";
                }
              ];
              definedAliases = [ "@sp" ];
            };

            nixpkgs = {
              name = "nixpkgs packages";
              urls = [
                {
                  template =
                    "https://search.nixos.org/packages?query={searchTerms}";
                }
              ];
              icon =
                "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };
          };
        };

        userChrome = ''
          /* Stylix-compatible Zen UI customization can go here. */
        '';
      };
    };
  };
}
