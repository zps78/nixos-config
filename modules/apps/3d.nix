# ../../modules/apps/3d.nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    blender          # 3D Creation/Animation/Publishing System
    bambu-studio     # PC Software for BambuLab's 3D printers
    freecad          # General purpose Open Source 3D CAD/MCAD/CAx/CAE/PLM modeler
    meshlab          # System for processing and editing 3D triangular meshes
#   netgen           # Atomatic 3d tetrahedral mesh generator
    openscad         # 3D parametric model compiler
    orca-slicer      # G-code generator for 3D printers (including Bambulabs)
  ];
}
