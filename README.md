-:1:-
BIOS: disable secure boot

-:2:-
NixOS install

-:3:-
sudo nano /etc/nixos/configuration.nix:
  + packages:
      git

-:4:-
sudo nixos-rebuild switch
cd ~
git clone https://github.com/zps78/nixos-config.git
sudo nixos-rebuild switch --flake .#kuro

-:5:-
IPTVnator playlist
  http://iptv-org.github.io/iptv/index.m3u

Kate
  Settings
    Configure Kate
      Session
        Load last used session
      Projects
        Restore open projects
