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
    kernelParams = [ "bnx2x.mask_tx_fault=3" ];

    kernelPackages = let
      linux_custom_pkg = { fetchFromGitHub, buildLinux, ... } @ args:

        buildLinux (args // rec {
          version = "5.15.75";
          modDirVersion = version;

          src = fetchFromGitHub {
            owner = "asdrubalini";
            repo = "linux-bnx2x";
            rev = "c958ada747c167adb3307b082752464fa3259dad";
            sha256 = "sha256-+82jMzNIgORGJd6iYJalR+oiPHHx3vIjS9F+bE9QyQM=";
          };

          kernelPatches = [];

        } // (args.argsOverride or {}));
      linux_custom = pkgs.callPackage linux_custom_pkg {};
    in
      pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_custom);

    kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };
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
    nat.enable = false;
    firewall.enable = false;

    nftables = {
      enable = true;
      ruleset = ''
        table ip global {
          chain inbound_world {
              # accepting ping (icmp-echo-request) for diagnostic purposes.
              # However, it also lets probes discover this host is alive.
              # This sample accepts them within a certain rate limit:
              #
              # icmp type echo-request limit rate 5/second accept

              # allow SSH connections from some well-known internet host
              #ip saddr 81.209.165.42 tcp dport ssh accept
          }

          chain inbound_private {
              # accepting ping (icmp-echo-request) for diagnostic purposes.
              icmp type echo-request limit rate 5/second accept

              # allow DHCP, DNS and SSH from the private network
              ip protocol . th dport vmap { tcp . 22 : accept, udp . 53 : accept, tcp . 53 : accept, udp . 67 : accept}
          }

          chain inbound {
              type filter hook input priority 0; policy drop;

              # Allow traffic from established and related packets, drop invalid
              ct state vmap { established : accept, related : accept, invalid : drop }

              # allow loopback traffic, anything else jump to chain for further evaluation
              iifname vmap { lo : accept, ppp0 : jump inbound_world, lan : jump inbound_private }

              # the rest is dropped by the above policy
          }

          chain forward {
              type filter hook forward priority 0; policy drop;

              # Allow traffic from established and related packets, drop invalid
              ct state vmap { established : accept, related : accept, invalid : drop }

              # connections from the internal net to the internet or to other
              # internal nets are allowed
              iifname lan accept

              # the rest is dropped by the above policy
          }

          chain postrouting {
              type nat hook postrouting priority 100; policy accept;

              # masquerade private IP addresses
              ip saddr 10.0.0.0/20 oifname ppp0 masquerade
          }
        }
      '';
    };

    vlans = {
      wan = { id = 835; interface = "enp1s0f0"; };
    };

    bridges = {
      "lan" = { interfaces = [ "enp1s0f1" "enp6s18" ]; };
    };

    interfaces = {
      # enp1s0f0.ipv4.addresses = [ { address = "192.168.1.1"; prefixLength = 24; } ];
      enp1s0f0 = {
        macAddress = "00:11:22:aa:bb:cc";
        useDHCP = false;
      };

      wan = {
        macAddress = "00:11:22:aa:bb:cc";
        useDHCP = true;
      };

      # Lan
      lan = {
        ipv4.addresses = [ {
          address = "10.0.0.1";
          prefixLength = 20;
        } ];

	      mtu = 1492;
      };

      enp6s18 = {
        useDHCP = false;
	      mtu = 1492;
      };

      enp1s0f1 = {
        useDHCP = false;
	      mtu = 1492;
      };
    };

    dhcpcd = {
      persistent = true;
      allowInterfaces = [ "wan" ];
      extraConfig = ''
        send vendor-class-identifier "Technicolor_DGA4131FWB/dslforum.org";
      '';
    };

    nameservers = [ "1.1.1.1" ];
    # defaultGateway = "10.0.0.200";
  };

  services.pppd = {
    enable = true;
    peers = {
      tim = {
        # Autostart the PPPoE session on boot
        autostart = true;
        enable = true;
        config = ''
          plugin rp-pppoe.so

          wan

          name "0264087024@alicebiz.routed"
          password "timadsl"

          persist
          maxfail 0
          holdoff 5
	        mtu 1492

          defaultroute
	        replacedefaultroute
        '';
      };
    };
  };

  services.dhcpd4 = {
    enable = true;
    interfaces = [ "lan" ];

    extraConfig = ''
      option subnet-mask 255.255.240.0;
      option broadcast-address 10.0.15.254;
      option routers 10.0.0.1;
      option domain-name-servers 10.0.0.3;

      subnet 10.0.0.0 netmask 255.255.240.0 {
        range 10.0.2.0 10.0.3.255;
      }
    '';
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

  environment.systemPackages = with pkgs; [
    ethtool
    conntrack-tools
    ppp
  ];

  programs.neovim.enable = true;
  programs.neovim.viAlias = true;
  programs.fish.enable = true;

  services.iperf3 = {
    enable = true;
    openFirewall = true;
    verbose = true;
  };

  # services.caddy = {
    # enable = true;
    # virtualHosts."10.0.0.1".extraConfig = ''
      # reverse_proxy http://192.168.1.10
    # '';
  # };

  services.qemuGuest.enable = true;

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  users.users."giovanni".openssh.authorizedKeys.keys =
    [
      (import ../ssh-keys/the-hydra.nix).key
      (import ../ssh-keys/proxmox.nix).key
    ];

  system.stateVersion = "22.05";
}
