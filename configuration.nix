{
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot = {
    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
      systemd-boot = {
        enable = true;
      };
    };
    supportedFilesystems = [
      "zfs"
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      caddy
      fd
      gcc
      go
      nixfmt
      ripgrep
      rustup
      speedtest-cli
    ];
  };

  networking = {
    hostId = "3ef6eefe";
    hostName = "themachine";
    tempAddresses = "enabled";
  };

  nix = {
    settings = {
      experimental-features = [
        "flakes"
        "nix-command"
      ];
    };
  };

  programs = {
    fish = {
      enable = true;
    };

    git = {
      enable = true;
    };

    nix-ld = {
      enable = true;
    };

    vim = {
      defaultEditor = true;
      enable = true;
    };
  };

  services = {
    iperf3 = {
      enable = true;
      openFirewall = true;
    };

    openssh = {
      enable = true;
      openFirewall = true;
      ports = [
        5492
      ];
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    tzupdate = {
      enable = true;
    };
  };

  system = {
    stateVersion = "25.11";
  };

  systemd = {
    services = {
      "backup" = {
        serviceConfig = {
          Restart = lib.mkForce "no";
          Type = "oneshot";
        };
        startAt = "4:0";
      };

      "network-containers" = {
        path = with pkgs; [
          docker
        ];
        serviceConfig = {
          RemainAfterExit = true;
          Type = "oneshot";
        };
        script = ''
          docker network inspect containers &> /dev/null || docker network create containers --ipv6
        '';
        wantedBy = [
          "multi-user.target"
        ];
      };
    };
  };

  users = {
    defaultUserShell = pkgs.fish;
    mutableUsers = false;
    users = {
      pkoenig10 = {
        extraGroups = [
          "docker"
          "wheel"
        ];
        hashedPasswordFile = "/etc/nixos/password";
        isNormalUser = true;
        openssh = {
          authorizedKeys = {
            keys = [
              "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDiwVSNNMmWj+9/ecQsqs8mg/5IBo+RkvKj9n+ENITOYBWxGGky8Cr2U4HBTCiRMP97TpQsrhaEAocK2fmI6F92XE3SLEJ6BnmJcClBmOMd0Fy761EWbRml1oIHxHPlCh095pxlzPRaV/QknaU6KYOyocQ5cd/yb/dM4pliJhT8ShVEma4VRqg/KgEImz0xQ7PiYStHKpZYbL5tD0fT4pU3XvvjSiwkFDa0SYtvnwYywYyTCbIUcF5JDOifIQ78o4iyc+AYPYavuUC5ztX2GnrVO2j+G7ArOoseacg+FjunK+k0jArSU4TXR7zlbjmgghwTkK3VRo2zB/ZZluRS+aDLE2fOqduK2ThQ/ZcuOJjCVmBpOhfNco2qTYFqK4UdLUmTEmT1ZYrBkELEZ7KkIna1T3tyEeDE1LCsd/QgLrcYJOjfgbHngclysPh2gSpne+bvxVOyKMRG11+xLg6tkwrVJro2F4mO0mOE9A0A4zaR6vr6xFLCsouZm0U3TWob7XhViVOVCMDuwKPh3bKn1Ixjes8Nh0pIhxBt4jo+TmPm8iP8pKGBjEONMOsO7IQre1w21F2v5BqiMonLYQRkO2OP07arh+QINlD0pTfQtEbf2QaJZE36C8+MArUzM3e4XYsbOcrqHFU5+544UmEl0ckW21XBf6uesdTQALFTnvXqcQ=="
            ];
          };
        };
        uid = 1000;
      };
    };
  };

  virtualisation = {
    oci-containers = {
      backend = "docker";

      containers = {
        auth = {
          environmentFiles = [
            "/etc/nixos/auth/.env"
          ];
          image = "pkoenig10/auth-oidc";
          networks = [
            "containers"
          ];
          pull = "always";
          serviceName = "auth";
          user = "1000:100";
          volumes = [
            "/etc/nixos/auth/config.yml:/config.yml:ro"
          ];
        };

        backup = {
          autoStart = false;
          environment = {
            GOOGLE_APPLICATION_CREDENTIALS = "/credentials.json";
          };
          environmentFiles = [
            "/etc/nixos/backup/.env"
          ];
          image = "pkoenig10/backup-google";
          pull = "always";
          serviceName = "backup";
          user = "1000:100";
          volumes = [
            "/config:/config:ro"
            "/etc/nixos:/etc/nixos:ro"
            "/etc/nixos/backup/config.yml:/config.yml:ro"
            "/etc/nixos/backup/credentials.json:/credentials.json:ro"
          ];
        };

        caddy = {
          environmentFiles = [
            "/etc/nixos/caddy/.env"
          ];
          image = "pkoenig10/caddy";
          networks = [
            "containers"
          ];
          ports = [
            "443:443"
            "443:443/udp"
          ];
          pull = "always";
          serviceName = "caddy";
          user = "1000:100";
          volumes = [
            "/config/caddy/config:/config"
            "/config/caddy/data:/data"
            "/etc/nixos/caddy/Caddyfile:/etc/caddy/Caddyfile:ro"
          ];
        };

        plex = {
          devices = [
            "/dev/dri"
          ];
          extraOptions = [
            "--tmpfs=/transcode"
          ];
          image = "linuxserver/plex";
          networks = [
            "containers"
          ];
          ports = [
            "32400:32400"
          ];
          pull = "always";
          serviceName = "plex";
          user = "1000:100";
          volumes = [
            "/config/plex/config:/config"
            "/data:/data"
          ];
        };

        prowlarr = {
          image = "linuxserver/prowlarr";
          networks = [
            "containers"
          ];
          pull = "always";
          serviceName = "prowlarr";
          user = "1000:100";
          volumes = [
            "/config/prowlarr/config:/config"
          ];
        };

        radarr = {
          image = "linuxserver/radarr";
          networks = [
            "containers"
          ];
          pull = "always";
          serviceName = "radarr";
          user = "1000:100";
          volumes = [
            "/config/radarr/config:/config"
            "/data:/data"
          ];
        };

        seerr = {
          image = "seerr/seerr";
          networks = [
            "containers"
          ];
          pull = "always";
          serviceName = "seerr";
          user = "1000:100";
          volumes = [
            "/config/seerr/config:/app/config"
          ];
        };

        sonarr = {
          image = "linuxserver/sonarr";
          networks = [
            "containers"
          ];
          pull = "always";
          serviceName = "sonarr";
          user = "1000:100";
          volumes = [
            "/config/sonarr/config:/config"
            "/data:/data"
          ];
        };

        tautulli = {
          image = "linuxserver/tautulli";
          networks = [
            "containers"
          ];
          pull = "always";
          serviceName = "tautulli";
          user = "1000:100";
          volumes = [
            "/config/tautulli/config:/config"
          ];
        };

        telegraf = {
          environment = {
            HOST_DEV = "/host/dev";
            HOST_ETC = "/host/etc";
            HOST_PROC = "/host/proc";
            HOST_ROOT = "/host/";
            HOST_RUN = "/host/run";
            HOST_SYS = "/host/sys";
            HOST_VAR = "/host/var";
            HOST_MOUNT_PREFIX = "/host";
          };
          environmentFiles = [
            "/etc/nixos/telegraf/.env"
          ];
          extraOptions = [
            "--group-add=131"
          ];
          image = "telegraf";
          networks = [
            "host"
          ];
          pull = "always";
          serviceName = "telegraf";
          user = "1000:100";
          volumes = [
            "/:/host:ro"
            "/etc/nixos/telegraf/telegraf.conf:/etc/telegraf/telegraf.conf:ro"
            "/var/run/docker.sock:/var/run/docker.sock"
          ];
        };

        transmission = {
          capabilities = {
            NET_ADMIN = true;
          };
          environment = {
            PUID = "1000";
            PGID = "100";
          };
          environmentFiles = [
            "/etc/nixos/transmission/.env"
          ];
          image = "haugene/transmission-openvpn";
          networks = [
            "containers"
          ];
          pull = "always";
          serviceName = "transmission";
          volumes = [
            "/config/transmission/config:/config"
            "/data:/data"
          ];
        };
      };
    };

    docker = {
      daemon = {
        settings = {
          userland-proxy = false;
        };
      };
      enable = true;
    };
  };
}
