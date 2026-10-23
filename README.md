# Themachine on Flatcar or Fedora CoreOS

Choose one of [`flatcar/config.bu`](flatcar/config.bu) and
[`fcos/config.bu`](fcos/config.bu). Each target directory also contains its
Podman Quadlets and Telegraf configuration. The backup manifest is embedded in
each Butane config. These files are generated from `generate-butane.py`, which
also contains the SSH public key and backup manifest entries.

Regenerate and transpile from the repository root with a recent Butane:

```sh
python3 generate-butane.py
butane --strict --files-dir . flatcar/config.bu > flatcar/config.ign
butane --strict --files-dir . fcos/config.bu > fcos/config.ign
```

Pass **one** Ignition file to a fresh installation of its matching OS. Ignition
applies on first boot; editing a Butane or Quadlet file later requires updating
the running host separately. The generated Ignition files contain no secrets.

## Filesystem and migration

The new layout uses `/etc/themachine` for service configuration and secrets,
`/var/lib/themachine/config` for application state, and
`/var/lib/themachine/data` for the ZFS dataset. The dataset remains `pool/data`
with `mountpoint=legacy`. The `var-lib-themachine-data.mount` unit imports the
existing pool and mounts the dataset before the data dependent Quadlets start.
The configs do not format disks or create a pool.

Before switching hosts, back up the current config and data trees. Move the
application state tree to `/var/lib/themachine/config`, retaining UID 1000 and
GID 100 ownership. Keep the data on `pool/data`. The new backup container still
sees application state at `/config`, while its manifest reads service files at
`/etc/themachine`. The backup container mounts that directory once, including
its Google credentials, and also mounts the manifest at the image's `/config.yml`
path. Restore these private files before starting the related
containers:

```sh
sudo install -d -m 0755 /etc/themachine/auth /etc/themachine/transmission
```

```text
/etc/themachine/auth/.env
/etc/themachine/auth/config.yml
/etc/themachine/backup/.env
/etc/themachine/backup/credentials.json
/etc/themachine/caddy/.env
/etc/themachine/telegraf/.env
/etc/themachine/transmission/.env
```

Ignition creates the `backup`, `caddy`, and `telegraf` subdirectories when it
writes their configuration files. The parent `/etc/themachine` directory is
declared once as root owned with mode 0755; permissions on restored files and
subdirectories must be set separately.

The existing `.env.template` files document the variables. Make bind mounted
secret files readable by UID 1000 and keep access restricted. Quadlets check
for required files before starting; long running services retry when files are
missing. Run a missed backup after restoration with
`systemctl start themachine-backup.service`.

The OS installer manages its EFI, root, and swap partitions. The old root,
boot, and swap UUIDs are not included in these configs. Verify the mount and
services before moving traffic:

```sh
systemctl status var-lib-themachine-data.mount containers-network.service
systemctl status themachine-caddy.service themachine-plex.service
systemctl list-timers 'themachine-*'
podman ps
```

The `containers.network` Quadlet creates the IPv6 capable Podman network.
Application Quadlets use it for name based discovery. Caddy publishes 443
TCP/UDP, Plex publishes 32400 TCP, and the iperf3 Quadlet serves TCP 5201 on
the host network. Other application ports stay on the container network.
The backup timer runs at 04:00, and the Podman prune timer runs weekly.
All images are pulled when their service starts.

## Flatcar

The config enables Flatcar's Podman and ZFS system extensions and masks the
default Docker service and socket. Its SSH socket drop-in listens only on port
5492. Login as `pkoenig10` with the configured public key. The Podman socket
is enabled so Telegraf can use its Docker compatible API. Check Telegraf's
Docker input on the target host. Flatcar's ZFS extension is experimental;
verify that it is available on the release you deploy.

## Fedora CoreOS

The Quadlets run as rootful Podman services. Login as the stock `core` account,
which owns UID 1000; creating another account with the same UID would conflict.
The image must provide OpenZFS tools and a kernel compatible ZFS module before
the data mount can work. It must also provide `policycoreutils-python-utils`:
the SSH service uses `semanage` to allow port 5492 under SELinux. Test this
custom image on a console before relying on remote access.

Both targets set `SecurityLabelDisable=true` for these rootful containers so
they can read existing bind mounted data without relabeling it. This reduces
SELinux separation between the containers and host files. Review that choice
and test auth, Caddy, Transmission VPN, Plex hardware access, Telegraf, and
backup before switching production traffic. Apply desired host access rules
at the network edge or in a tested host firewall configuration.

## Host tools

Butane provisions first boot files, users, and systemd units. The OS image
supplies its bootloader, firmware, root filesystem, and networking. The old
Fish shell, timezone updater, Nix tooling, and developer CLI packages are not
provisioned. Add host tools through the target OS's supported extension or
container mechanism if needed.

References: [Podman Quadlets](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html),
[container Quadlet options](https://docs.podman.io/en/latest/markdown/podman-container.unit.5.html),
[Flatcar system extensions](https://www.flatcar.org/docs/latest/sys-ext/),
[Flatcar ZFS](https://www.flatcar.org/docs/latest/os-config/storage/zfs/), and
[Butane specifications](https://coreos.github.io/butane/specs/).
