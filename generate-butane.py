#!/usr/bin/env python3
"""Generate Butane and Podman Quadlet files for both target distributions."""

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent
STATE = "/var/lib/themachine"
CONFIG = f"{STATE}/config"
DATA = f"{STATE}/data"
ETC = "/etc/themachine"
DATA_UNIT = "var-lib-themachine-data.mount"
SSH_PUBLIC_KEY = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDiwVSNNMmWj+9/ecQsqs8mg/5IBo+RkvKj9n+ENITOYBWxGGky8Cr2U4HBTCiRMP97TpQsrhaEAocK2fmI6F92XE3SLEJ6BnmJcClBmOMd0Fy761EWbRml1oIHxHPlCh095pxlzPRaV/QknaU6KYOyocQ5cd/yb/dM4pliJhT8ShVEma4VRqg/KgEImz0xQ7PiYStHKpZYbL5tD0fT4pU3XvvjSiwkFDa0SYtvnwYywYyTCbIUcF5JDOifIQ78o4iyc+AYPYavuUC5ztX2GnrVO2j+G7ArOoseacg+FjunK+k0jArSU4TXR7zlbjmgghwTkK3VRo2zB/ZZluRS+aDLE2fOqduK2ThQ/ZcuOJjCVmBpOhfNco2qTYFqK4UdLUmTEmT1ZYrBkELEZ7KkIna1T3tyEeDE1LCsd/QgLrcYJOjfgbHngclysPh2gSpne+bvxVOyKMRG11+xLg6tkwrVJro2F4mO0mOE9A0A4zaR6vr6xFLCsouZm0U3TWob7XhViVOVCMDuwKPh3bKn1Ixjes8Nh0pIhxBt4jo+TmPm8iP8pKGBjEONMOsO7IQre1w21F2v5BqiMonLYQRkO2OP07arh+QINlD0pTfQtEbf2QaJZE36C8+MArUzM3e4XYsbOcrqHFU5+544UmEl0ckW21XBf6uesdTQALFTnvXqcQ=="


def scalar(value):
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, bool):
        return str(value).lower()
    return str(value)


def yaml(value, indent=0):
    pad = " " * indent
    if isinstance(value, dict):
        lines = []
        for key, item in value.items():
            if isinstance(item, (dict, list)):
                lines.append(f"{pad}{key}:")
                lines.append(yaml(item, indent + 2))
            elif isinstance(item, str) and "\n" in item:
                lines.append(f"{pad}{key}: |")
                lines.extend(f"{pad}  {line}" for line in item.rstrip("\n").split("\n"))
            else:
                lines.append(f"{pad}{key}: {scalar(item)}")
        return "\n".join(lines)
    if isinstance(value, list):
        lines = []
        for item in value:
            if isinstance(item, (dict, list)):
                rendered = yaml(item, indent + 2).split("\n")
                lines.append(f"{pad}- {rendered[0].lstrip()}")
                lines.extend(rendered[1:])
            else:
                lines.append(f"{pad}- {scalar(item)}")
        return "\n".join(lines)
    raise TypeError(type(value))


def file(path, *, inline=None, local=None, overwrite=False):
    contents = {"inline": inline} if local is None else {"local": local}
    return {"path": path, "mode": 0o644, **({"overwrite": True} if overwrite else {}), "contents": contents}


def directory(path, user=1000, group=100):
    return {"path": path, "mode": 0o755, "user": {"id": user}, "group": {"id": group}}


def unit(name, contents=None, enabled=None, mask=None, dropins=None):
    result = {"name": name}
    if enabled is not None:
        result["enabled"] = enabled
    if mask is not None:
        result["mask"] = mask
    if contents is not None:
        result["contents"] = contents
    if dropins is not None:
        result["dropins"] = dropins
    return result


def volume(source, target, readonly=False):
    return f"{source}:{target}{':ro' if readonly else ''}"


def container_specs():
    """One source of truth for the container options shared by both targets."""
    return {
        "auth": {
            "Image": "docker.io/pkoenig10/auth-oidc",
            "Network": "containers.network",
            "User": "1000:100",
            "EnvironmentFile": f"{ETC}/auth/.env",
            "Volume": [volume(f"{ETC}/auth/config.yml", "/config.yml", True)],
        },
        "caddy": {
            "Image": "docker.io/pkoenig10/caddy",
            "Network": "containers.network",
            "User": "1000:100",
            "EnvironmentFile": f"{ETC}/caddy/.env",
            "PublishPort": ["443:443", "443:443/udp"],
            "Volume": [
                volume(f"{CONFIG}/caddy/config", "/config"),
                volume(f"{CONFIG}/caddy/data", "/data"),
                volume(f"{ETC}/caddy/Caddyfile", "/etc/caddy/Caddyfile", True),
            ],
        },
        "plex": {
            "Image": "docker.io/linuxserver/plex",
            "Network": "containers.network",
            "User": "1000:100",
            "AddDevice": "/dev/dri",
            "Tmpfs": "/transcode",
            "PublishPort": "32400:32400",
            "Volume": [volume(f"{CONFIG}/plex/config", "/config"), volume(DATA, "/data")],
        },
        "prowlarr": {
            "Image": "docker.io/linuxserver/prowlarr",
            "Network": "containers.network",
            "User": "1000:100",
            "Volume": volume(f"{CONFIG}/prowlarr/config", "/config"),
        },
        "radarr": {
            "Image": "docker.io/linuxserver/radarr",
            "Network": "containers.network",
            "User": "1000:100",
            "Volume": [volume(f"{CONFIG}/radarr/config", "/config"), volume(DATA, "/data")],
        },
        "seerr": {
            "Image": "docker.io/seerr/seerr",
            "Network": "containers.network",
            "User": "1000:100",
            "Volume": volume(f"{CONFIG}/seerr/config", "/app/config"),
        },
        "sonarr": {
            "Image": "docker.io/linuxserver/sonarr",
            "Network": "containers.network",
            "User": "1000:100",
            "Volume": [volume(f"{CONFIG}/sonarr/config", "/config"), volume(DATA, "/data")],
        },
        "tautulli": {
            "Image": "docker.io/linuxserver/tautulli",
            "Network": "containers.network",
            "User": "1000:100",
            "Volume": volume(f"{CONFIG}/tautulli/config", "/config"),
        },
        "telegraf": {
            "Image": "docker.io/library/telegraf",
            "Network": "host",
            "EnvironmentFile": f"{ETC}/telegraf/.env",
            "Environment": [
                "HOST_DEV=/host/dev", "HOST_ETC=/host/etc", "HOST_PROC=/host/proc",
                "HOST_ROOT=/host/", "HOST_RUN=/host/run", "HOST_SYS=/host/sys",
                "HOST_VAR=/host/var", "HOST_MOUNT_PREFIX=/host",
            ],
            "Volume": [
                volume("/", "/host", True),
                volume(f"{ETC}/telegraf/telegraf.conf", "/etc/telegraf/telegraf.conf", True),
                volume("/run/podman/podman.sock", "/var/run/docker.sock"),
            ],
        },
        "transmission": {
            "Image": "docker.io/haugene/transmission-openvpn",
            "Network": "containers.network",
            "EnvironmentFile": f"{ETC}/transmission/.env",
            "Environment": ["PUID=1000", "PGID=100"],
            "AddCapability": "NET_ADMIN",
            "Volume": [volume(f"{CONFIG}/transmission/config", "/config"), volume(DATA, "/data")],
        },
        "backup": {
            "Image": "docker.io/pkoenig10/backup-google",
            "Network": "containers.network",
            "User": "1000:100",
            "EnvironmentFile": f"{ETC}/backup/.env",
            "Environment": f"GOOGLE_APPLICATION_CREDENTIALS={ETC}/backup/credentials.json",
            "Volume": [
                volume(CONFIG, "/config", True),
                volume(ETC, ETC, True),
                volume(f"{ETC}/backup/config.yml", "/config.yml", True),
            ],
        },
        "iperf3": {
            "Image": "docker.io/networkstatic/iperf3",
            "Network": "host",
            "Exec": "--server",
        },
    }


def secret_files(name):
    paths = {
        "auth": [f"{ETC}/auth/.env", f"{ETC}/auth/config.yml"],
        "caddy": [f"{ETC}/caddy/.env"],
        "telegraf": [f"{ETC}/telegraf/.env"],
        "transmission": [f"{ETC}/transmission/.env"],
        "backup": [f"{ETC}/backup/.env", f"{ETC}/backup/credentials.json"],
    }
    return paths.get(name, [])


def render_quadlet(name, fields, variant):
    lines = [
        "[Unit]",
        f"Description=Themachine {name} container",
    ]
    if name != "iperf3":
        lines.extend([f"Requires={DATA_UNIT}", f"After={DATA_UNIT}"])
    if name == "telegraf":
        lines.extend(["Requires=podman.socket", "After=podman.socket"])
    if variant == "flatcar":
        lines.append("After=ensure-sysext.service")
    lines += ["", "[Container]", f"Image={fields['Image']}", f"ContainerName={name}", "Pull=always", "SecurityLabelDisable=true"]
    for key, value in fields.items():
        if key == "Image":
            continue
        for item in value if isinstance(value, list) else [value]:
            lines.append(f"{key}={item}")
    lines += ["", "[Service]"]
    if name == "backup":
        # A timer must see the service return to inactive after each run.
        lines.append("Type=oneshot")
    else:
        lines += ["Restart=always", "RestartSec=30", "TimeoutStartSec=900", "TimeoutStopSec=30"]
    lines += [f"ExecStartPre=/usr/bin/test -f {path}" for path in secret_files(name)]
    if name != "backup":
        lines += ["", "[Install]", "WantedBy=multi-user.target"]
    return "\n".join(lines) + "\n"


def write_assets(variant):
    target = ROOT / variant
    quadlets = target / "quadlets"
    quadlets.mkdir(parents=True, exist_ok=True)
    (quadlets / "containers.network").write_text("[Network]\nNetworkName=containers\nIPv6=true\n")
    for name, fields in container_specs().items():
        (quadlets / f"themachine-{name}.container").write_text(render_quadlet(name, fields, variant))
    telegraf = (ROOT / "telegraf/telegraf.conf").read_text().replace('    "/data",', f'    "{DATA}",')
    (target / "telegraf.conf").write_text(telegraf)


def backup_manifest():
    backup_paths = [
        "config/plex/config/Library/Application Support/Plex Media Server/Preferences.xml",
        "config/seerr/config/settings.json",
        "config/prowlarr/config/Backups/**",
        "config/radarr/config/Backups/**",
        "config/sonarr/config/Backups/**",
        "config/tautulli/config/backups/**",
        "config/transmission/config/transmission-home/settings.json",
        "etc/themachine/**/.env",
        "etc/themachine/auth/config.yml",
        "etc/themachine/backup/credentials.json",
    ]
    return "files:\n" + "".join(f"  - {path}\n" for path in backup_paths)


def generate(variant):
    write_assets(variant)
    flatcar = variant == "flatcar"
    user = {
        "name": "pkoenig10" if flatcar else "core",
        **({"uid": 1000, "primary_group": "users", "groups": ["wheel"]} if flatcar else {}),
        "ssh_authorized_keys": [SSH_PUBLIC_KEY],
    }
    doc = {
        "variant": variant,
        "version": "1.1.0" if flatcar else "1.7.0",
        "passwd": {"users": [user]},
        "storage": {"directories": [], "files": [], "trees": [{"local": f"{variant}/quadlets", "path": "/etc/containers/systemd"}]},
        "systemd": {"units": []},
    }
    dirs = doc["storage"]["directories"]
    files = doc["storage"]["files"]
    units = doc["systemd"]["units"]
    dirs += [directory(STATE), directory(CONFIG), directory(DATA), directory(ETC, 0, 0)]
    for app in ("caddy", "plex", "prowlarr", "radarr", "seerr", "sonarr", "tautulli", "transmission"):
        dirs.append(directory(f"{CONFIG}/{app}"))
        dirs.append(directory(f"{CONFIG}/{app}/config"))
    dirs.append(directory(f"{CONFIG}/caddy/data"))
    files += [
        file("/etc/hostname", inline="themachine\n", overwrite=True),
        file("/etc/ssh/sshd_config.d/20-themachine.conf", inline="Port 5492\nPasswordAuthentication no\nPermitRootLogin no\n"),
        file(f"{ETC}/caddy/Caddyfile", local="caddy/Caddyfile"),
        file(f"{ETC}/backup/config.yml", inline=backup_manifest()),
        file(f"{ETC}/telegraf/telegraf.conf", local=f"{variant}/telegraf.conf"),
    ]
    if flatcar:
        files.append(file("/etc/flatcar/enabled-sysext.conf", inline="podman\nzfs\n"))
    units += [
        unit("zpool-import-pool.service", "[Unit]\nDescription=Import existing ZFS pool\n" + ("After=ensure-sysext.service\n" if flatcar else "") + f"Before={DATA_UNIT}\n\n[Service]\nType=oneshot\nRemainAfterExit=yes\nExecStart=/bin/sh -c 'zpool list -H pool >/dev/null 2>&1 || zpool import -N pool'\n"),
        unit(DATA_UNIT, f"[Unit]\nDescription=Mount existing pool/data dataset\nRequires=zpool-import-pool.service\nAfter=zpool-import-pool.service\n\n[Mount]\nWhat=pool/data\nWhere={DATA}\nType=zfs\n\n[Install]\nWantedBy=multi-user.target\n", enabled=True),
        unit("themachine-backup.timer", "[Unit]\nDescription=Run themachine backup daily\n\n[Timer]\nOnCalendar=*-*-* 04:00:00\nPersistent=true\nUnit=themachine-backup.service\n\n[Install]\nWantedBy=timers.target\n", enabled=True),
        unit("themachine-prune.service", "[Unit]\nDescription=Prune unused Podman images and volumes\n\n[Service]\nType=oneshot\nExecStart=/usr/bin/podman system prune --all --volumes --force\n"),
        unit("themachine-prune.timer", "[Unit]\nDescription=Prune containers weekly\n\n[Timer]\nOnCalendar=Sun *-*-* 03:00:00\nPersistent=true\nUnit=themachine-prune.service\n\n[Install]\nWantedBy=timers.target\n", enabled=True),
        unit("podman.socket", enabled=True),
    ]
    if flatcar:
        units += [
            unit("docker.socket", mask=True),
            unit("docker.service", mask=True),
            unit("sshd.socket", dropins=[{"name": "10-themachine-port.conf", "contents": "[Socket]\nListenStream=\nListenStream=5492\n"}]),
        ]
    else:
        units.append(unit("sshd.service", dropins=[{
            "name": "10-themachine-selinux-port.conf",
            "contents": "[Service]\nExecStartPre=/bin/sh -c '/usr/sbin/semanage port -a -t ssh_port_t -p tcp 5492 || /usr/sbin/semanage port -m -t ssh_port_t -p tcp 5492'\n",
        }]))
    (ROOT / variant / "config.bu").write_text(
        "# Generated by ../generate-butane.py; transpile with --files-dir repository-root.\n" + yaml(doc) + "\n"
    )


if __name__ == "__main__":
    for variant in ("flatcar", "fcos"):
        generate(variant)
