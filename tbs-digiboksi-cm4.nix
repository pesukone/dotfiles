# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }:

let #tbs-driver = config.boot.kernelPackages.callPackage ./tbs/default.nix { };
    mc-schema = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/MythTV/mythtv/12706dac98a6ffe1b256bed0f67d8bee6f377e61/mythtv/database/mc.sql";
      sha256 = "p1vRj876qYxxkJW0qc9L8fTDNfUN4SCduOUhpixDol8=";
    };
    unstable = import
      (builtins.fetchTarball https://github.com/nixos/nixpkgs/tarball/d604c4a964bcd78d4c00298552fcaba2150b06fc)
      { config = config.nixpkgs.config; };

in {
  imports =
    [
      <nixos-hardware/raspberry-pi/4>
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_rpi4;
  boot.kernelModules = [ "via_camera" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ ];
  boot.tmp.useTmpfs = true;
  #boot.tmp.tmpfsSize = "50G";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  hardware = {
    firmware = [
      (
        let
          tbsFirmware = pkgs.fetchzip {
            url = "www.tbsdtv.com/download/document/linux/tbs-tuner-firmwares_v1.0.tar.bz2";
            sha256 = "Es0cCEBq6w0wiStChzmQmbaGJLURQR7kDOrPU6kUebw=";
            stripRoot = false;
          };
        in
        pkgs.runCommandNoCC "tbs-firmware" { } ''
          mkdir -p $out/lib/firmware/
          cp ${tbsFirmware}/* $out/lib/firmware/
        ''
      )
    ];

    raspberry-pi."4".apply-overlays-dtmerge.enable = true;
    raspberry-pi."4".fkms-3d.enable = true;
    deviceTree = {
      enable = true;
      filter = "bcm2711-rpi-4*.dtb";
    };
  };

  networking.hostName = "tor-digiboksi"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Europe/Helsinki";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };

  # Configure console keymap
  console.keyMap = "fi";

  # Configure the X11 windowing system.
  services.xserver = {
    enable = true;
    layout = "fi";
    xkbVariant = "";
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    videoDrivers = [ "modesetting" "fbdev" ];
  };
  

  # services.xserver.xkbOptions = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  systemd.services.tbs = {
    enable = false;
    description = "Load the tbs modules in right order";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      /run/current-system/sw/bin/insmod /run/current-system/kernel-modules/lib/modules/$(uname -r)/tbs/cx24117.ko.xz
      /run/current-system/sw/bin/modprobe saa716x_tbs_dvb int_type=1
    '';
  };

  services.mysql = {
    enable = false;
    package = pkgs.mariadb;
    initialScript = mc-schema;
  };

  #services.logind.extraConfig = ''
  #  RuntimeDirectorySize=50G
  #'';

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     firefox
  #     tree
  #   ];
  # };

  users.users.jussi = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    initialPassword = "secret1234";
    packages = with pkgs; [];
  };

  #users.users.pzuser = {
  #  isNormalUser = true;
  #  createHome = true;
  #  packages = with pkgs; [
  #    steamcmd
  #  ];
  #};

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.buildMachines = [{
    hostName = "pesukone";
    protocol = "ssh-ng";
    systems = [ "x86_64-linux" "aarch64-linux" ];
    maxJobs = 32;
    speedFactor = 2;
    supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    mandatoryFeatures = [ ];
  }];
  nix.distributedBuilds = true;
  nix.extraOptions = ''
    builders-use-substitutes = true
  '';

  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    ripgrep
    binutils
    #mythtv
    tmux
    htop
    libraspberrypi
    raspberrypi-eeprom
    git
    gnumake
    #mongodb
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  #services.openssh.forwardX11 = true;
  services.openssh.settings.X11Forwarding = true;

  virtualisation.docker.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}

