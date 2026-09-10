# ../../modules/apps-user/zed.nix
{ config, pkgs, lib, ... }:

{
  options.myApps.zed.enable =
    lib.mkEnableOption "Zed";

  config = lib.mkIf config.myApps.zed.enable {

    programs.zed-editor = {
      enable = true;

      # ----------------------
      # Language servers/tools
      # ----------------------
      extraPackages = with pkgs; [
        nixd                  # Nix LSP
        tombi                 # TOML LSP
        claude-agent-acp      # Claude Code, via the Agent Client Protocol
        # marksman            # Markdown LSP (Kate had this) - add if wanted
        # clang-tools         # C/C++ (clangd) (Kate had this) - add if wanted
      ];

      # ----------------------
      # Extensions (auto-installed on first launch; needs network once)
      # ----------------------
      extensions = [
        "nix"                 # hasit/zed-nix
        "toml"                # zed-extensions/toml
        "kdl"                 # elkowar/zed-kdl - syntax highlighting for niri configs
      ];

      # ----------------------
      # Settings
      # ----------------------
      userSettings = {
        tab_size = 2;
        hard_tabs = false;

        format_on_save = "on";

        # Follow Noctalia's theme. Noctalia's "zed" template regenerates
        # ~/.config/zed/themes/noctalia.json on every wallpaper/theme
        # change; "mode = system" tracks its light/dark switch via the
        # xdg-desktop-portal color-scheme. Swap to the "* Transparent"
        # variants for a translucent editor.
        theme = {
          mode = "system";
          light = "Noctalia Light";
          dark = "Noctalia Dark";
        };

        git_panel = {
          tree_view = true;
        };

        tabs = {
          git_status = true;
        };

        languages = {
          Nix = {
            language_servers = [ "nixd" ];
          };
          TOML = {
            language_servers = [ "tombi" ];
          };
        };

        # Claude Code as an external agent (Agent panel: Cmd/Ctrl-?).
        # The binary comes from claude-agent-acp above. Auth is a one-time
        # "/login" in the agent thread (reuses the claude-code CLI login
        # if you're already signed in there) - that part isn't declarative.
        agent_servers = {
          "Claude Code" = {
            command = "claude-agent-acp";
            args = [ ];
            env = { };
          };
        };
      };
    };
  };
}
