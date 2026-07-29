firmware: disable secure boot

install nixos

sudo nano /etc/nixos/configuration.nix:

  - add packages git + vscodium

sudo nixos-rebuild switch

cd ~

git clone https://github.com/zps78/nixos-config.git
