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

  nixpkgs = {
    config = {
      allowUnfree = true;
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
    caddy = {
      configFile = "/etc/nixos/caddy/Caddyfile";
      # TODO: this doesn't work, the data dir is ~/.local/share/caddy
      # dataDir = "/config/caddy2";
      enable = true;
      environmentFile = "/etc/nixos/caddy/.env";
      group = "users";
      package = pkgs.caddy.withPlugins {
        hash = "sha256-eDCHOuPm+o3mW7y8nSaTnabmB/msw6y2ZUoGu56uvK0=";
        plugins = [ "github.com/caddy-dns/cloudflare@v0.2.3" ];
      };
      user = "pkoenig10";
    };

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

    # overseerr = {
    #   # TODO: change this
    #   dataDir = "/config/overseerr/config";
    #   enable = true;
    #   group = "users";
    #   user = "pkoenig10";
    # };

    # TODO: transcode to RAM
    # TODO: Remove old IPs
    plex = {
      # TODO: change this
      dataDir = "/config/plex/config/Library/Application Support";
      enable = true;
      group = "users";
      openFirewall = true;
      user = "pkoenig10";
    };

    # prowlarr = {
    #   # TODO: change this
    #   dataDir = "/config/prowlarr/config";
    #   enable = true;
    #   group = "users";
    #   user = "pkoenig10";
    # };

    radarr = {
      # TODO: change this
      dataDir = "/config/radarr/config";
      enable = true;
      group = "users";
      user = "pkoenig10";
    };

    sonarr = {
      # TODO: change this
      dataDir = "/config/sonarr/config";
      enable = true;
      group = "users";
      user = "pkoenig10";
    };

    tautulli = {
      # TODO: change this
      configFile = "/config/tautulli/config/config.ini";
      dataDir = "/config/tautulli/config";
      enable = true;
      group = "users";
      user = "pkoenig10";
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
      caddy = {
        # TODO: it's unfortunate we have to directly configure the systemd service
        environment = {
          XDG_CONFIG_HOME = "/config/caddy/config";
          XDG_DATA_HOME = "/config/caddy/data";
        };
        serviceConfig = {
          ProtectHome = lib.mkForce false;
        };
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
