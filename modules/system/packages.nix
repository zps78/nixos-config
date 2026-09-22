# ../../modules/system/packages.nix
#
# Base CLI toolbox present on every host (unconditional). Editor/LSP
# tooling lives with the editors in apps-user; shell prompt (oh-my-posh)
# and dconf live in the home / desktop modules.
#
# Not listed: anything NixOS already ships in environment.corePackages /
# defaultPackages (curl, gnugrep, gnused, gawk, xz, zstd, rsync, strace,
# which, nano, ...).
{ pkgs, ... }:

{
  environment.variables.EDITOR = "nano";

  environment.systemPackages = with pkgs; [

    # networking
    arp-scan       # ARP scanning and host discovery tool
    aria2          # Lightweight multi-protocol download utility
    dnsutils       # DNS utilities (dig, nslookup, host)
    doggo          # Modern DNS client for humans
    ethtool        # Display and configure Ethernet devices
    gping          # Ping with a live graph
    httpie         # Human-friendly HTTP client
    ipcalc         # IPv4/IPv6 address calculator
    iperf3         # Network bandwidth measurement tool
    mtr            # Network diagnostic and traceroute tool
    nmap           # Network discovery and security auditing
    socat          # Multipurpose relay for bidirectional data transfer
    tcpdump        # Command-line packet analyzer
    wakeonlan      # Send Wake-on-LAN magic packets
    wget           # Retrieve files using HTTP, HTTPS and FTP

    # system information
    btop           # Resource monitor with process management
    dmidecode      # SMBIOS/DMI hardware information tool
    fastfetch      # Fast system information tool
    lm_sensors     # Hardware monitoring utilities
    nvme-cli       # NVMe management and monitoring utility
    pciutils       # PCI device inspection tools (lspci)
    smartmontools  # SMART monitoring tools for storage devices
    usbutils       # USB device utilities (lsusb)

    # storage and filesystems
    croc           # Secure and simple file transfer tool
    duf            # Modern disk usage/free space utility
    gdu            # Fast disk usage analyzer
    hdparm         # Hard disk parameter and performance utility
    parted         # Disk partition manipulation tool
    rclone         # Sync files to and from cloud storage
    yazi           # Blazing fast terminal file manager (async I/O)

    # development
    git-lfs        # Git extension for large files
    gnumake        # Build automation tool
    hyperfine      # Command-line benchmarking tool
    just           # Command runner and task automation tool

    # nix
    nix-output-monitor  # Readable, structured build output (nom)
    nvd                 # Diff package/version changes between generations

    # search and text processing
    bat            # cat with syntax highlighting
    fd             # Simple, fast and user-friendly find alternative
    fzf            # Command-line fuzzy finder
    jc             # Convert command output to JSON
    jq             # Command-line JSON processor
    ripgrep        # Fast recursive search tool (rg)
    sad            # Search and replace with diff preview
    yq-go          # Portable YAML/JSON/XML processor

    # archives
    p7zip          # 7z archive support
    unrar          # Extract RAR archives
    unzip          # Extract ZIP archives
    zip            # ZIP archive utility

    # debugging
    file           # Determine file types
    lsof           # List open files and network connections
    psmisc         # Miscellaneous process utilities (killall, pstree, fuser)
    pv             # Monitor data through pipelines
    tree           # Display directory trees

    # monitoring
    iftop          # Real-time network bandwidth monitor
    iotop-c        # Monitor disk I/O usage by process
    procs          # Modern replacement for ps
    systemctl-tui  # Terminal UI for systemd services

    # security and crypto
    age            # modern file encryption
    openssl        # TLS/SSL and cryptography toolkit

    # media
    ffmpeg-full    # Complete multimedia framework

    # documentation
    man-pages         # Linux man-pages (sections 2, 3, ...)
    man-pages-posix   # POSIX man-pages
    tealdeer          # Fast tldr client
  ];
}
