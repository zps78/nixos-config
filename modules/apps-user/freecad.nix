# ../../modules/apps-user/freecad.nix
{ config, pkgs, lib, inputs, ... }:

let
  cfg = config.myApps.freecad;

  # The MCP server Claude actually talks to (launched by Claude Desktop/Code,
  # not run inside FreeCAD). The in-FreeCAD half is addon/FreeCADMCP, linked
  # below via home.file - it's a plain RPC server with no third-party deps,
  # so it needs no packaging of its own.
  freecad-mcp-server = pkgs.python3Packages.buildPythonApplication {
    pname = "freecad-mcp";
    version = "0.1.26";
    pyproject = true;
    src = inputs.freecad-mcp;
    build-system = [ pkgs.python3Packages.hatchling ];
    dependencies = with pkgs.python3Packages; [ mcp validators ];
    # No tests here - the suite expects a live FreeCAD RPC connection.
    doCheck = false;
    # Upstream's wheel metadata can declare a dependency floor (e.g.
    # certifi) newer than what nixpkgs currently pins; certifi's only
    # content is a CA bundle, no API surface, so a slightly older pinned
    # version is harmless - skip the static check rather than chase it.
    dontCheckRuntimeDeps = true;
  };

  # FreeCAD >=1.0 keeps its user data (and Mod/) under a version-tagged dir,
  # e.g. ~/.local/share/FreeCAD/v1-1 for 1.1.x - NOT the unversioned
  # ~/.local/share/FreeCAD/Mod path docs/READMEs assume. Derived from the
  # package version so a FreeCAD bump doesn't silently break the addon links.
  modDir = ".local/share/FreeCAD/v${lib.replaceStrings ["."] ["-"] (lib.versions.majorMinor pkgs.freecad.version)}/Mod";
in
{
  options.myApps.freecad = {
    enable = lib.mkEnableOption "FreeCAD";

    mcp.enable = lib.mkEnableOption ''
      freecad-mcp, which lets Claude Desktop/Code drive a live FreeCAD
      session - billed as normal usage under your existing Claude
      subscription, no separate API key. Linked declaratively into
      FreeCAD's version-tagged Mod directory instead of via FreeCAD's own
      Addon Manager.

      After rebuilding: restart FreeCAD, select the "MCP Addon" workbench,
      click "Start RPC Server", then add this to claude_desktop_config.json
      (not managed here - Claude Desktop owns and rewrites that file):
        "freecad": { "command": "freecad-mcp", "args": [] }
    '';

    gpt4freecad.enable = lib.mkEnableOption ''
      GPT4FreeCAD, a separate addon that turns a natural-language prompt
      into a parametric feature tree (not MCP/tool-calling, so it's not a
      substitute for the mcp.enable workflow above - a different way
      in). Zero third-party Python deps, so just the repo linked into
      Mod/ like FreeCADMCP above.

      It defaults to Google Gemini, which needs a paid API key entered in
      its Settings panel. To use it for free instead, switch its
      "Provider" dropdown to "Ollama / LM Studio" and point the Server URL
      at krieger's ollama container (see myServices.aiStack in
      modules/services/ai-stack.nix): http://krieger:11434 - this is the
      distinction that got GPT4FreeCAD dropped from this config
      previously, so it's worth restating up front this time.
    '';
  };

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      freecad
    ] ++ lib.optional cfg.mcp.enable freecad-mcp-server;

    home.file = lib.mkMerge [
      (lib.mkIf cfg.mcp.enable {
        "${modDir}/FreeCADMCP" = {
          source = "${inputs.freecad-mcp}/addon/FreeCADMCP";
          recursive = true;
        };
      })
      (lib.mkIf cfg.gpt4freecad.enable {
        "${modDir}/GPT4FreeCAD" = {
          source = inputs.gpt4freecad;
          recursive = true;
        };
      })
    ];
  };
}
