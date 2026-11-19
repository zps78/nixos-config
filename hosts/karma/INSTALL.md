# karma - install (phase 0)

Fresh NixOS on the Samsung 990 Pro (M.2_1), still in krieger's case,
with nothing from the Unraid karma attached. The layout matches
`hardware-configuration.nix`; change one, change the other.

Boot: Ventoy stick -> `nixos-fleet-installer-26.11...iso` (has ZFS).
Get a root shell (`sudo -i`). Ethernet into the Aquantia port.

## 1. Partition the 990 Pro

```sh
ls -l /dev/disk/by-id/ | grep -i 990          # find the whole-disk id (no -partN)
DISK=/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_1TB_XXXXXXXXXXXXXXX

wipefs -a "$DISK"
sgdisk --zap-all "$DISK"
sgdisk -n1:1M:+1G -t1:EF00 -c1:karma-esp "$DISK"
sgdisk -n2:0:0    -t2:BF00 -c2:karma-zfs "$DISK"
partprobe "$DISK"; udevadm settle
mkfs.vfat -F32 -n KARMA-ESP /dev/disk/by-partlabel/karma-esp
```

## 2. Root pool and datasets

```sh
zpool create -f \
  -o ashift=12 -o autotrim=on \
  -O compression=zstd -O atime=off -O xattr=sa -O acltype=posixacl \
  -O dnodesize=auto -O normalization=formD \
  -O mountpoint=none -O canmount=off \
  rpool /dev/disk/by-partlabel/karma-zfs

zfs create -o canmount=off rpool/local
zfs create -o canmount=off rpool/safe
for ds in local/root local/nix local/docker safe/var safe/home safe/appdata; do
  zfs create -o mountpoint=legacy rpool/$ds
done

# Never fill the pool to 100% (ZFS gets very slow / can't delete).
zfs create -o canmount=off -o mountpoint=none -o refreservation=50G rpool/reserved
```

## 3. Mount and install

```sh
mount -t zfs rpool/local/root /mnt
mkdir -p /mnt/{nix,var,home,srv/appdata,boot}
mount -t zfs rpool/local/nix      /mnt/nix
mount -t zfs rpool/safe/var       /mnt/var
mkdir -p /mnt/var/lib/docker
mount -t zfs rpool/local/docker   /mnt/var/lib/docker
mount -t zfs rpool/safe/home      /mnt/home
mount -t zfs rpool/safe/appdata   /mnt/srv/appdata
mount -o fmask=0077,dmask=0077 /dev/disk/by-partlabel/karma-esp /mnt/boot

# Install straight from GitHub - no local clone on the target. The working
# copy lives in the admin's home like on every other host (step 4).
nixos-install --flake github:zps78/nixos-config#karma
#   ^ asks for a root password at the end: set one. Root can't log in over
#     SSH (PermitRootLogin no); it's the emergency key for the console
#     (monitor + keyboard on the box) when SSH/the network is broken.
nixos-enter --root /mnt -c 'passwd zp'        # zp's sudo password - only needed
#   if the host key is new (reinstall): zp-password.age can't be decrypted
#   until the new key is added to secrets/secrets.nix and rekeyed (step 4)
```

Before rebooting, compare against the detected hardware:
`nixos-generate-config --root /mnt --show-hardware-config` - only
kernel modules should differ; copy any new ones into
`hardware-configuration.nix`.

```sh
umount -R /mnt && zpool export rpool && reboot
```

**Don't skip the export.** An unexported pool is still marked as in use
by the installer's hostid, and karma's initrd won't force-import it: the
first boot hangs at "A start job is running for Import ZFS pool rpool"
and ends in an unusable emergency mode. Recovery: boot the installer,
`zpool import -f -N rpool && zpool export rpool`, reboot.

## 4. First boot

- Console: plain getty on tty1 (no desktop); log in as zp, or root in an
  emergency. SSH is closed on the LAN (fleet design: SSH over Tailscale
  only), so the first step happens at the console:
- `sudo tailscale up --accept-dns --accept-routes --ssh --qr` -> scan,
  approve; the machine name becomes `karma-n5` (until the phase-6
  cutover). The flags must be typed here: the config's extraUpFlags are
  only applied automatically with an authKeyFile, which karma doesn't use.
  (On the pt console layout, mind the dashes - a typo gives "too many
  non-flag arguments".) From then on: `ssh zp@karma-n5`.
- Working copy of the config, as zp (same place as on the other hosts):
  `git clone https://github.com/zps78/nixos-config.git ~/nixos-config`
  Rebuild: `cd ~/nixos-config && git pull && sudo nixos-rebuild switch --flake .#karma`
- agenix: add the new host key to `secrets/secrets.nix` as `karma-host`
  (from `/etc/ssh/ssh_host_ed25519_key.pub`), add it to
  `home-gateway-mac.age`'s and `zp-password.age`'s recipients, `agenix -r`, rebuild.
- Check: `zpool status rpool`, `nvidia-smi` (both GPUs listed),
  `ip rule` (shows `from 192.168.1.7 lookup 100`),
  `ip route show table 100`.

## Later (not phase 0)

- Phase 6 cutover: hostName `karma`, LAN IP `.5`, Tailscale node rename +
  IP 100.101.102.5 + subnet route, optionally reuse the Unraid karma's
  SSH host keys (`/boot/config/ssh/` on the old box) so known_hosts and
  agenix keep working.
