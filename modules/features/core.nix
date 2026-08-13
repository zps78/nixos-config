# ../../modules/features/core.nix
{ pkgs, ... }:

{
  programs.oh-my-posh.enable = true;

  environment.systemPackages = with pkgs; [

    # networking
    arp-scan       # ARP scanning and host discovery tool
    aria2          # Lightweight multi-protocol download utility
    dnsutils       # DNS utilities (dig, nslookup, host)
    doggo          # Modern DNS client for humans
    ethtool        # Display and configure Ethernet devices
    gping          # Ping with a live graph
    httpie         # Human-friendly HTTP client
    iperf3         # Network bandwidth measurement tool
    ipcalc         # IPv4/IPv6 address calculator
    mtr            # Network diagnostic and traceroute tool
    nmap           # Network discovery and security auditing
    socat          # Multipurpose relay for bidirectional data transfer
    tcpdump        # Command-line packet analyzer
    wakeonlan      # Send Wake-on-LAN magic packets
    wget           # Retrieve files using HTTP, HTTPS and FTP
    curl           # Command-line data transfer tool

    # system information
    btop           # Resource monitor with process management
    fastfetch      # Fast system information tool
    lm_sensors     # Hardware monitoring utilities
    pciutils       # PCI device inspection tools (lspci)
    usbutils       # USB device utilities (lsusb)
    dmidecode      # SMBIOS/DMI hardware information tool
    smartmontools  # SMART monitoring tools for storage devices
    nvme-cli       # NVMe management and monitoring utility

    # storage and filesystems
    duf            # Modern disk usage/free space utility
    gdu            # Fast disk usage analyzer
    fio            # Flexible I/O benchmark and workload generator
    hdparm         # Hard disk parameter and performance utility
    parted         # Disk partition manipulation tool
    rclone         # Sync files to and from cloud storage
    rsync          # Fast incremental file transfer utility
    croc           # Secure and simple file transfer tool

    # development
    clang-tools    # Standalone command line tools for C++ development
    git            # Distributed version control system
    git-lfs        # Git extension for large files
    gnumake        # Build automation tool
    just           # Command runner and task automation tool
    helix          # Post-modern modal text editor
    marksman       # Language Server for Markdown
    nil            # Yet another language server for Nix
    nushell        # Modern shell focused on structured data
    oh-my-posh     # Prompt theme engine for any shell

    # search and text processing
    bat            # cat with syntax highlighting
    fd             # Simple, fast and user-friendly find alternative
    fzf            # Command-line fuzzy finder
    ripgrep        # Fast recursive search tool (rg)
    gnugrep        # Pattern matching and text search utility
    gnused         # Stream editor for filtering and transforming text
    gawk           # Pattern scanning and processing language
    jq             # Command-line JSON processor
    yq-go          # Portable YAML/JSON/XML processor
    jc             # Convert command output to JSON
    sad            # Search and replace with diff preview

    # archives
    zip            # ZIP archive utility
    unzip          # Extract ZIP archives
    p7zip          # 7-Zip archive manager
    unrar          # Extract RAR archives
    xz             # XZ compression utilities
    zstd           # Zstandard compression utilities

    # debugging
    lsof           # List open files and network connections
    strace         # Trace system calls and signals
    ltrace         # Trace library calls
    psmisc         # Miscellaneous process utilities
    file           # Determine file types
    which          # Locate executables in PATH
    tree           # Display directory trees
    pv             # Monitor data through pipelines

    # benchmarking
    hyperfine      # Command-line benchmarking tool
    sysbench       # Modular benchmark suite
    iperf3         # Network performance measurement tool
    fio            # Flexible I/O benchmark and workload generator

    # monitoring
    sysstat        # System performance monitoring tools
    iotop-c        # Monitor disk I/O usage by process
    iftop          # Real-time network bandwidth monitor
    procs          # Modern replacement for ps
    systemctl-tui  # Terminal UI for systemd services

    # security and crypto
    age            # modern file encryption
    openssl        # TLS/SSL and cryptography toolkit
    libargon2      # Argon2 password hashing library and tools

    # media
    ffmpeg-full    # Complete multimedia framework
    f3d            # Fast and minimalist 3D viewer using VTK
    # documentation
    tealdeer       # Fast tldr client
  ];
}
