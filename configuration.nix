{
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
      clang
      fd
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

    firewall = {
      allowedTCPPorts = [
        443
        32400
      ];
      allowedUDPPorts = [
        443
      ];
    };
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
    cron = {
      enable = true;
      systemCronJobs = [
        "*/5 * * * * pkoenig10 cd /etc/nixos && docker compose up -d ddns"
        "0   4 * * * pkoenig10 cd /etc/nixos && docker compose --profile task up -d --pull always"
      ];
    };

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
      # TODO(podman): Remove backend
      backend = "docker";

      containers = {
        caddy = {
          environmentFiles = [
            "/etc/nixos/caddy/.env"
          ];
          image = "pkoenig10/caddy";
          networks = [
            "host"
          ];
          pull = "always";
          serviceName = "caddy";
          user = "1000:100";
          volumes = [
            "/config/caddy/config:/config"
            "/config/caddy/data:/data"
            # TODO: Remove this?
            "/etc/localtime:/etc/localtime:ro"
            "/etc/nixos/caddy/Caddyfile:/etc/caddy/Caddyfile:ro"
          ];
        };

        overseerr = {
          image = "linuxserver/overseerr";
          networks = [
            "host"
          ];
          pull = "always";
          serviceName = "overseerr";
          user = "1000:100";
          volumes = [
            "/config/overseerr/config:/config"
            "/etc/localtime:/etc/localtime:ro"
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
            "host"
          ];
          pull = "always";
          serviceName = "plex";
          user = "1000:100";
          volumes = [
            "/config/plex/config:/config"
            # TODO: RequiresMountsFor?
            "/data/movies:/data/movies"
            "/data/tv:/data/tv"
            "/etc/localtime:/etc/localtime:ro"
          ];
        };

        prowlarr = {
          image = "linuxserver/prowlarr";
          networks = [
            "host"
          ];
          pull = "always";
          serviceName = "prowlarr";
          user = "1000:100";
          volumes = [
            "/config/prowlarr/config:/config"
            "/etc/localtime:/etc/localtime:ro"
          ];
        };

        radarr = {
          image = "linuxserver/radarr";
          networks = [
            "host"
          ];
          pull = "always";
          serviceName = "radarr";
          user = "1000:100";
          volumes = [
            "/config/radarr/config:/config"
            "/data/downloads:/data/downloads"
            "/data/movies:/data/movies"
            "/etc/localtime:/etc/localtime:ro"
          ];
        };

        sonarr = {
          image = "linuxserver/sonarr";
          networks = [
            "host"
          ];
          pull = "always";
          serviceName = "sonarr";
          user = "1000:100";
          volumes = [
            "/config/sonarr/config:/config"
            "/data/downloads:/data/downloads"
            "/data/tv:/data/tv"
            "/etc/localtime:/etc/localtime:ro"
          ];
        };

        tautulli = {
          image = "linuxserver/tautulli";
          networks = [
            "host"
          ];
          pull = "always";
          serviceName = "tautulli";
          user = "1000:100";
          volumes = [
            "/config/tautulli/config:/config"
            "/etc/localtime:/etc/localtime:ro"
          ];
        };

        telegraf = {
          environment = {
            # TODO: Are there more we need? Should these be alphabetized?
            HOST_ETC = "/hostfs/etc";
            HOST_PROC = "/hostfs/proc";
            HOST_RUN = "/hostfs/run";
            HOST_SYS = "/hostfs/sys";
            HOST_VAR = "/hostfs/var";
            HOST_MOUNT_PREFIX = "/hostfs";
          };
          environmentFiles = [
            "/etc/nixos/telegraf/.env"
          ];
          extraOptions = [
            # TODO(podman): Ghange group ID to 993 and make it stable
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
            "/:/hostfs:ro"
            "/etc/localtime:/etc/localtime:ro"
            "/etc/nixos/telegraf/telegraf.conf:/etc/telegraf/telegraf.conf:ro"
            "/var/run/docker.sock:/var/run/docker.sock"
            # TODO(podman): Change socket volume
            # "/run/podman/podman.sock:/run/podman/podman.sock"
          ];
        };

        # TODO: This routes all host traffic through the VPN
        transmission = {
          capabilities = {
            NET_ADMIN = true;
          };
          environment = {
            PUID = "1000";
            PGID = "100";
            TRANSMISSION_DOWNLOAD_DIR = "/data/downloads/completed";
            TRANSMISSION_INCOMPLETE_DIR = "/data/downloads/incomplete";
          };
          environmentFiles = [
            "/etc/nixos/transmission/.env"
          ];
          image = "haugene/transmission-openvpn";
          networks = [
            "host"
          ];
          pull = "always";
          serviceName = "transmission";
          volumes = [
            "/config/transmission/config:/config"
            "/data/downloads:/data/downloads"
            "/etc/localtime:/etc/localtime:ro"
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

    # TODO(podman): Enable podman
    # podman = {
    #   autoPrune = {
    #     enable = true;
    #     flags = [
    #       "--all"
    #     ];
    #   };
    #   enable = true;
    # };
  };
}
