1:
BIOS: disable secure boot

2:
NixOS install

3:
sudo nano /etc/nixos/configuration.nix:
  + packages:
    git
    vscodium

4:
sudo nixos-rebuild switch
cd ~
git clone https://github.com/zps78/nixos-config.git
