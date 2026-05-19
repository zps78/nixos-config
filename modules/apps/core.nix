# ../../modules/apps/core.nix
{ config, pkgs, ... }:

{
  programs.thunderbird.enable = true;
  environment.systemPackages = with pkgs; [
  # Core CLI tools
#   agenix
    btop             # Monitor of resources
    iperf3           # Tool to measure IP bandwidth using UDP or TCP
    fio              # Flexible IO Tester - an IO benchmark tool
    git              # Distributed version control system
    p7zip            # .7z, many formats, very important
    pciutils         # Collection of programs for inspecting and manipulating configuration of PCI devices
    rclone           # Command line program to sync files and directories to and from major cloud storage
    rsync            # Fast incremental file transfer utility
    usbutils         # Tools for working with USB devices, such as lsusb
    unrar            # .rar files (optional but useful)
    unzip            # .zip files
    wget             # Tool for retrieving files using HTTP, HTTPS, and FTP

  # Networking
    arp-scan         # ARP scanning and fingerprinting tool
#   eddie            # AirVPN's OpenVPN and WireGuard wrapper
    ethtool          # Utility for controlling network drivers and hardware
    netcat           # Utility which reads and writes data across network connections — LibreSSL implementation
    nfs-utils        # Linux user-space NFS utilities
    thunderbird      # Full-featured e-mail client

  # Multimedia
    audacity         # Sound editor with graphical UI
    blender          # 3D Creation/Animation/Publishing System
    bambu-studio     # PC Software for BambuLab's 3D printers
#   clipgrab         #Video downloader for YouTube and other sites
    ffmpeg-full      # Complete solution to record, convert and stream audio and video
    freecad          # General purpose Open Source 3D CAD/MCAD/CAx/CAE/PLM modeler
    gimp             # GNU Image Manipulation Program
    handbrake        # Tool for converting video files and ripping DVDs
    krita            # Free and open source painting application
    losslesscut-bin  # Swiss army knife of lossless video/audio editing
    meshlab          # System for processing and editing 3D triangular meshes
#   netgen           # Atomatic 3d tetrahedral mesh generator
    mkvtoolnix       # Cross-platform tools for Matroska
    openscad         # 3D parametric model compiler
    orca-slicer      # G-code generator for 3D printers (including Bambulabs)
    vlc              # Cross-platform media player and streaming server

  # Utilities
    ddrescue         # GNU ddrescue, a data recovery tool
    ddrescueview     # Tool to graphically examine ddrescue mapfiles
    ddrutility       # Set of utilities for hard drive data rescue
    rustdesk
    testdisk         # Data recovery utilities
  ];
}
