# Install

passwd nixos

parted /dev/nvme0n1 -- mklabel gpt

parted /dev/nvme0n1 -- mkpart esp fat32 1MB 512MB
parted /dev/nvme0n1 -- mkpart root ext4 512MB -8GB
parted /dev/nvme0n1 -- mkpart swap linux-swap -8GB 100%

parted /dev/nvme0n1 -- set 1 esp on

mkfs.fat -F 32 -n boot /dev/nvme0n1p1
mkfs.ext4 -L root /dev/nvme0n1p2
mkswap -L swap /dev/nvme0n1p3

mount /dev/disk/by-label/root /mnt

mkdir -p /mnt/boot
mount -o umask=077 /dev/disk/by-label/boot /mnt/boot

swapon /dev/nvme0n1p3

nixos-generate-config --root /mnt

mkpasswd > /mnt/etc/nixos/password

nixos-install --no-root-passwd

# ZFS

zpool create -o ashift=12 -O mountpoint=none pool raidz2 \
    /dev/disk/by-id/wwn-0x5000000000000001 \
    /dev/disk/by-id/wwn-0x5000000000000002 \
    /dev/disk/by-id/wwn-0x5000000000000003 \
    /dev/disk/by-id/wwn-0x5000000000000004 \
    /dev/disk/by-id/wwn-0x5000000000000005 \
    /dev/disk/by-id/wwn-0x5000000000000006

zfs create -o mountpoint=legacy -o recordsize=1M pool/data

mkdir /data
mount -t zfs pool/data /data

chown pkoenig10:users /data
