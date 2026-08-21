# ../../modules/apps/zen-browser.nix
{ config, inputs, pkgs, lib, ... }:
let
  cfg = config.myApps.zen-browser;

  extension = shortId: guid: {
    name = guid;
    value = {
      install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
      installation_mode = "normal_installed";
    };
  };

  prefs = {
    # Check these out at about:config
    "extensions.autoDisableScopes" = 0;
    "browser.backspace_action" = 0;
    "extensions.pocket.enabled" = false;
    # ...
  };

  extensions = [
    # To add additional extensions, find it on addons.mozilla.org, find
    # the short ID in the url (like https://addons.mozilla.org/en-US/firefox/addon/!SHORT_ID!/)
    # Then go to https://addons.mozilla.org/api/v5/addons/addon/!SHORT_ID!/ to get the guid
    (extension "ublock-origin" "uBlock0@raymondhill.net")
    (extension "sponsorblock" "sponsorBlocker@ajay.app")
    (extension "keepa" "amptra@keepa.com")
    (extension "proton-pass" "78272b6fa58f4a1abaac99321d503a20@proton.me")
    (extension "print-edit-we" "printedit-we@DW-dev")
    (extension "video-downloadhelper" "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}")
    (extension "consent-o-matic" "gdpr@cavi.au.dk")
    (extension "torrent-control" "{e6e36c9a-8323-446c-b720-a176017e38ff}")
    # ...
  ];

in
{
  options.myApps.zen-browser.enable =
    lib.mkEnableOption "Zen Browser";
  
  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.wrapFirefox
        inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-unwrapped
        {
          extraPrefs = lib.concatLines (
            lib.mapAttrsToList (
              name: value: ''lockPref(${lib.strings.toJSON name}, ${lib.strings.toJSON value});''
            ) prefs
          );

          extraPolicies = {
            DisableTelemetry = true;
            ExtensionSettings = builtins.listToAttrs extensions;

            SearchEngines = {
              Default = "@ddg";
              Add = [
                {
                  Name = "Startpage";
                  URLTemplate = "https://www.startpage.com/sp/search?query={searchTerms}";
                  IconURL = "https://www.startpage.com/favicon.ico";
                  Alias = "@sp";
                }
                {
                  Name = "nixpkgs packages";
                  URLTemplate = "https://search.nixos.org/packages?query={searchTerms}";
                  IconURL = "https://wiki.nixos.org/favicon.ico";
                  Alias = "@np";
                }
              ];
            };
          };
        }
      )
    ];
  };
}
