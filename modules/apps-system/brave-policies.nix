# ../../modules/apps-system/brave-policies.nix
#
# Chromium managed-policy JSON for Brave - machine-wide (Chromium has no
# per-profile policy scope, unlike Firefox), applies regardless of which
# users on this host have myApps.brave.enable. home-manager's
# programs.brave module has no settings/policy option of its own (just
# enable/extensions/package/...), so this is the only way to get Brave
# close to what zen-browser.nix already does via Firefox prefs/policies.

{ config, lib, ... }:

{
  options.myFeatures.brave-policies.enable =
    lib.mkEnableOption "Brave privacy policy defaults (managed policy JSON)";

  config = lib.mkIf config.myFeatures.brave-policies.enable {
    environment.etc."brave/policies/managed/nixos.json".text = builtins.toJSON {
      # Block Google's "Sign in with Google" One Tap widget SDK - same
      # URL/reasoning as firefox.nix / zen-browser.nix's WebsiteFilter.
      URLBlocklist = [ "accounts.google.com/gsi/*" ];

      # No "translate this page?" popup. Chromium only exposes an
      # on/off switch here, not Firefox's narrower "don't auto-offer,
      # keep the manual icon" (browser.translations.automaticallyPopup) -
      # this disables translate entirely, there's no manual fallback.
      TranslateEnabled = false;

      # No password-save prompts / password manager - Proton Pass
      # handles this instead (matches zen's signon.rememberSignons).
      PasswordManagerEnabled = false;

      # Telemetry off: Brave's own usage ping/P3A/web-discovery, plus
      # Chromium's crash-report metrics switch. Confirmed working set
      # (not guessed) - matches a known-good community nix-config.
      BraveStatsPingEnabled = false;
      BraveP3AEnabled = false;
      BraveWebDiscoveryEnabled = false;
      MetricsReportingEnabled = false;

      # Not used, cuts both the attack surface (dApp site permissions,
      # seed phrase storage) and the setup nags. Note the inconsistent
      # naming vs the rest of this file - confirmed via Brave's own
      # group policy docs, not guessed.
      BraveWalletDisabled = true;

      # Leo AI chat sidebar - not used. Confirmed via a real Linux
      # managed-policy report (not guessed).
      BraveAIChatEnabled = false;
    };
  };
}
