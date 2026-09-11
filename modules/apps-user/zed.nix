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
        clang-tools           # clangd, for C/C++ - also covers ACSIL (see below)
        # marksman            # Markdown LSP (Kate had this) - add if wanted
      ];

      # ----------------------
      # Extensions (auto-installed on first launch; needs network once)
      # ----------------------
      extensions = [
        "nix"                 # hasit/zed-nix
        "toml"                # zed-extensions/toml
        "kdl"                 # elkowar/zed-kdl - syntax highlighting for niri configs
        "git-firefly"         # d1y/git_firefly - .gitattributes/.gitconfig/.gitignore/rebase-todo highlighting
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

        # ACSIL (SierraChart's study/indicator API) is plain C++ against
        # SierraChart's own sierrachart.h header - not a distinct
        # language, so it just rides Zed's built-in C++ support +
        # clangd above. For real completion/diagnostics against the SDK,
        # clangd needs the SierraChart SDK include path, via a
        # .clangd/compile_flags.txt in the study source folder (project-
        # level, not something to declare here).

        # No Zed extension exists for MQL4/MQL5 (checked the extension
        # registry - neither is packaged; a raw tree-sitter grammar for
        # MQL5 exists at github.com/mskelton/tree-sitter-mql5 but nobody
        # has wrapped it as a Zed extension, and no MQL4 grammar exists
        # at all). Approximating with C++ syntax highlighting until then
        # - real bracket/keyword highlighting for the C-family parts,
        # just not MQL-aware (misses `#property`, `input`/`extern`,
        # trade functions like OrderSend/iMA as keywords).
        file_types = {
          "C++" = [ "mq4" "mq5" "mqh" ];
        };

        # Two independent Claude agents in the Agent panel (Cmd/Ctrl-?):
        #  - "Claude Code": our own entry, pinned to the claude-agent-acp
        #    package above - reproducible, no network needed to fetch it.
        #  - "claude-acp": Zed's own "ACP Registry" entry (its Finish
        #    Setup screen offers to "Install" this) - Zed fetches and
        #    manages its own copy at runtime, outside Nix. Declared here
        #    too so every user gets it pre-wired instead of having to
        #    click through Finish Setup.
        # Both need "type" now - Zed 1.19 flagged the old command-only
        # form as outdated and rewrote it to this schema on its own.
        # Auth is a one-time "/login" per agent, not declarative - each
        # reuses the claude-code CLI login if you're already signed in.
        agent_servers = {
          "Claude Code" = {
            type = "custom";
            command = "claude-agent-acp";
            args = [ ];
            env = { };
          };
          "claude-acp" = {
            type = "registry";
          };
        };
      };
    };
  };
}
