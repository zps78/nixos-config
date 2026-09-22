# ../../modules/apps-system/claude-desktop.nix
# Claude Desktop (Anthropic's official Linux build, repackaged for Nix by
# github:nmcbride/claude-desktop-nix) - the general chat/Projects/MCP app,
# distinct from the claude-code CLI toggled in apps-user/claude-code.nix.
{ config, inputs, lib, ... }:

{
  imports = [ inputs.claude-desktop.nixosModules.default ];

  options.myFeatures.claude-desktop.enable =
    lib.mkEnableOption "Claude Desktop";

  config = lib.mkIf config.myFeatures.claude-desktop.enable {
    programs.claude-desktop = {
      enable = true;
      # Sandboxed browser/desktop-automation VM (KVM/QEMU/virtiofsd) - off
      # for now, no host virtualization plumbing set up for it yet.
      cowork.enable = false;
    };
  };
}
