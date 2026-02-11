{
  ...
}:

{
  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/8e7d99f6-f82d-4c14-9bb6-58999b8207c1";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/2617-A23B";
      fsType = "vfat";
      options = [
        "umask=0077"
      ];
    };

    "/data" = {
      device = "pool/data";
      fsType = "zfs";
    };
  };

  hardware = {
    cpu = {
      intel = {
        updateMicrocode = true;
      };
    };
    enableRedistributableFirmware = true;
  };

  nixpkgs = {
    hostPlatform = "x86_64-linux";
  };

  swapDevices = [
    {
      device = "/dev/disk/by-uuid/4051e18e-a6de-40dc-b5ca-48414f4b17e2";
    }
  ];
}
