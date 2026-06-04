# ../../modules/apps/core.nix
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop             # Monitor of resources
    curl             # Command line tool for transferring files with URL syntax
    dig              # Domain name server
    iperf3           # Tool to measure IP bandwidth using UDP or TCP
    fio              # Flexible IO Tester - an IO benchmark tool
    git              # Distributed version control system
    lm_sensors       # Tools for reading hardware sensors - maintained fork
    lsof             # Tool to list open files
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
    wakeonlan        # Perl script for waking up computers via Wake-On-LAN magic packets

    inetutils        # Collection of common network programs
    nmap             # Free and open source utility for network discovery and security auditing

  # Multimedia
    audacity         # Sound editor with graphical UI
#   clipgrab         # Video downloader for YouTube and other sites
    ffmpeg-full      # Complete solution to record, convert and stream audio and video
    gimp             # GNU Image Manipulation Program
    handbrake        # Tool for converting video files and ripping DVDs
    krita            # Free and open source painting application
    losslesscut-bin  # Swiss army knife of lossless video/audio editing
    mkvtoolnix       # Cross-platform tools for Matroska
    vlc              # Cross-platform media player and streaming server

  # Utilities
    ddrescue         # GNU ddrescue, a data recovery tool
    ddrescueview     # Tool to graphically examine ddrescue mapfiles
    ddrutility       # Set of utilities for hard drive data rescue
    testdisk         # Data recovery utilities
  ];
}
