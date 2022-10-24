{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../services/ssh-secure.nix
  ];

  boot = {
    initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "ahci" "virtio_pci" "sr_mod" "virtio_blk" ];
    initrd.kernelModules = [ ];
    kernelModules = [ ];
    extraModulePackages = [ ];

    kernelPackages = pkgs.linuxPackages_5_15;

    kernelPatches = [ {
      name = "bnx2x hsgmii";
      patch = ../patches/bnx2x_warpcore_8727_2_5g_sgmii_txfault.patch;
    } ];

  };

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/a00746d8-02d2-4b0b-8226-3745c33918c8";
      fsType = "btrfs";
      options = [ "subvol=@" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/a00746d8-02d2-4b0b-8226-3745c33918c8";
      fsType = "btrfs";
      options = [ "subvol=@home" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/a00746d8-02d2-4b0b-8226-3745c33918c8";
      fsType = "btrfs";
      options = [ "subvol=@nix" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/6CAD-375A";
      fsType = "vfat";
    };

  swapDevices = [ ];

  networking = {
    interfaces.enp1s0f0.useDHCP = true;

    interfaces.enp1s0f1.ipv4.addresses = [ {
      address = "10.0.0.1";
      prefixLength = 20;
    } ];

    interfaces.enp6s18.useDHCP = true;

    defaultGateway = "10.0.0.200";
    nameservers = [ "10.0.0.3" ];
  };

  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;

  hardware.firmware = with pkgs; [ linux-firmware ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nixpkgs.config.allowUnfree = true;
  networking.hostName = "router";
  time.timeZone = "Europe/Rome";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    earlySetup = true;
    font = "${pkgs.terminus_font}/share/consolefonts/ter-132n.psf.gz";
    packages = with pkgs; [ terminus_font ];
  };

  users = {
    mutableUsers = false;
    extraUsers.root.hashedPassword = (import ../passwords).password;

    users.giovanni = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      hashedPassword = (import ../passwords).password;
    };
  };

  environment.systemPackages = with pkgs; [ ethtool ];

  programs.neovim.enable = true;
  programs.neovim.viAlias = true;

  services.iperf3 = {
    enable = true;
    openFirewall = true;
    verbose = true;
  };

  nix = {
    settings = {
      # substituters = [ "ssh://asdrubalini.xyz" ];
    };

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  users.users."giovanni".openssh.authorizedKeys.keys =
    [
      (import ../ssh-keys/the-hydra.nix).key
      (import ../ssh-keys/proxmox.nix).key
    ];
  
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  system.stateVersion = "22.05";
}
