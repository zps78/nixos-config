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
  };
in
{
  options.myApps.freecad = {
    enable = lib.mkEnableOption "FreeCAD";

    aiAddons.enable = lib.mkEnableOption ''
      AI addons for FreeCAD: GPT4FreeCAD (structured-geometry generation,
      no extra setup) and freecad-mcp (lets Claude Desktop/Code drive a live
      FreeCAD session). Linked declaratively into ~/.local/share/FreeCAD/Mod
      instead of via FreeCAD's own Addon Manager.

      After rebuilding: restart FreeCAD, select the "MCP Addon" workbench,
      click "Start RPC Server", then add this to claude_desktop_config.json
      (not managed here - Claude Desktop owns and rewrites that file):
        "freecad": { "command": "freecad-mcp", "args": [] }
    '';
  };

  # ----------------------
  # Packages
  # ----------------------
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      freecad
    ] ++ lib.optional cfg.aiAddons.enable freecad-mcp-server;

    home.file = lib.mkIf cfg.aiAddons.enable {
      ".local/share/FreeCAD/Mod/GPT4FreeCAD" = {
        source = inputs.gpt4freecad;
        recursive = true;
      };
      ".local/share/FreeCAD/Mod/FreeCADMCP" = {
        source = "${inputs.freecad-mcp}/addon/FreeCADMCP";
        recursive = true;
      };
    };
  };
}
