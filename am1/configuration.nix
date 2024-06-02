# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let tbs-driver = config.boot.kernelPackages.callPackage ./tbs/default.nix { };
    mc-schema = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/MythTV/mythtv/1f2d417433b5f507a344ff243cbd7a1933a7e12d/mythtv/database/mc.sql";
      sha256 = "p1vRj876qYxxkJW0qc9L8fTDNfUN4SCduOUhpixDol8=";
    };
/*
    unstable = import
      (builtins.fetchTarball https://github.com/nixos/nixpkgs/tarball/798e23beab9b5cba4d6f05e8b243e1d4535770f3)
      { config = config.nixpkgs.config; };
*/
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.kernelPackages = pkgs.linuxPackages_6_1;
  boot.kernelModules = [ "via_camera" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ ];

  #hardware.firmware = [
  #  (
  #    let
  #      tbsFirmware = pkgs.fetchzip {
  #        url = "www.tbsdtv.com/download/document/linux/tbs-tuner-firmwares_v1.0.tar.bz2";
  #        sha256 = "JAwDc+NT3nbhbUfVKCk7oXsEblgY67X80okUIWxQjMg=";
  #        stripRoot = false;
  #      };
  #    in
  #    pkgs.runCommandNoCC "tbs-firmware" { } ''
  #      mkdir -p $out/lib/firmware/
  #      cp ${tbsFirmware}/* $out/lib/firmware/
  #    ''
  #  )
  #];

  networking.hostName = "am1"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Helsinki";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fi_FI.UTF-8";
    LC_IDENTIFICATION = "fi_FI.UTF-8";
    LC_MEASUREMENT = "fi_FI.UTF-8";
    LC_MONETARY = "fi_FI.UTF-8";
    LC_NAME = "fi_FI.UTF-8";
    LC_NUMERIC = "fi_FI.UTF-8";
    LC_PAPER = "fi_FI.UTF-8";
    LC_TELEPHONE = "fi_FI.UTF-8";
    LC_TIME = "fi_FI.UTF-8";
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "fi";
    xkbVariant = "";
    #enable = true;
    #displayManager.gdm.enable = true;
    #desktopManager.gnome.enable = true;
  };

  systemd.services.tbs = {
    enable = false;
    description = "Load the tbs modules in right order";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      /run/current-system/sw/bin/modprobe -r cx24117
      /run/current-system/sw/bin/insmod /run/current-system/kernel-modules/lib/modules/$(uname -r)/tbs/cx24117.ko.xz
      /run/current-system/sw/bin/modprobe saa716x_tbs_dvb int_type=1
    '';
  };

  services.mysql = {
    enable = false;
    package = pkgs.mariadb;
    initialScript = mc-schema;
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    ensureDatabases = [
      "reseptisofta-dev"
      "reseptisofta-prod"
      "verolaskuri-dev"
      "verolaskuri-prod"
    ];
    enableTCPIP = true;
    authentication = pkgs.lib.mkOverride 10 ''
      #type database DBuser origin-address  auth-method
      #ipv4
      host  all      all    127.0.0.1/32    trust
      host  all      all    192.168.50.1/24 trust

      #ipv6 
      host  all      all    ::1/128        trust

      #type database          DBuser       auth-method optional_ident_map
      local reseptisofta-dev  reseptisofta trust
      local reseptisofta-prod reseptisofta trust
      local verolaskuri-dev   verolaskuri  trust
      local verolaskuri-prod  verolaskuri  trust
      local sameuser          all          peer        map=superuser_map
    '';
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE reseptisofta WITH LOGIN;
      GRANT ALL PRIVILEGES ON DATABASE reseptisofta-dev TO reseptisofta;
      GRANT ALL PRIVILEGES ON DATABASE reseptisofta-prod TO reseptisofta;

      CREATE ROLE verolaskuri WITH LOGIN;
      GRANT ALL PRIVILEGES ON DATABASE verolaskuri-dev TO verolaskuri;
      GRANT ALL PRIVILEGES ON DATABASE verolaskuri-prod TO verolaskuri;

      --CREATE ROLE nixcloud WITH LOGIN PASSWORD 'nixcloud' CREATEDB;
      --CREATE DATABASE nixcloud;
      --GRANT ALL PRIVILEGES ON DATABASE nixcloud TO nixcloud;
    '';
    identMap = ''
      # ArbitraryMapName systemUser DBUser
      superuser_map      root       postgres
      superuser_map      postgres   postgres
      # Let other names login as themselves
      superuser_map      /^(.*)$    \1
    '';
  };

  # Configure console keymap
  console.keyMap = "fi";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jussi = {
    isNormalUser = true;
    description = "Jussi Aalto";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  users.users.pzuser = {
    isNormalUser = true;
    createHome = true;
    packages = with pkgs; [
      steamcmd
    ];
  };

  users.users.overleaf = {
    isNormalUser = true;
    createHome = true;
    extraGroups = [ "docker" ];
    packages = with pkgs; [
      git
      gnumake
    ];
  };

  #systemd.user.services.zomboid = {
  #  wantedBy = [ "multi-user.target" ];
  #  enable = true;
  #  serviceConfig = {
  #    ExecStart = pkgs.lib.escapeShellArgs [
  #      "/run/current-system/sw/bin/steam-run"
  #      "/home/pzuser/pzserver/start-server.sh"
  #      "<"
  #      "/home/pzuser/pzserver/zomboid.control"
  #    ];
  #    ExecStop = pkgs.lib.escapeShellArgs [
  #      "/run/current-system/sw/bin/echo save > /home/pzuser/pzserver/zomboid.control;"
  #      "/run/current-system/sw/bin/sleep 15;"
  #      "/run/current-system/sw/bin/echo quit > /home/pzuser/pzserver/zomboid.control"
  #    ];
  #    PrivateTmp = true;
  #    Type = "simple";
  #    User = "pzuser";
  #    Group = "pzuser";
  #    WorkingDirectory = "/home/pzuser/";
  #    Sockets = "zomboid.socket";
  #    KillSignal = "SIGCONT";
  #  };
  #};

  #systemd.sockets.zomboid = {
  #  bindsTo = [ "zomboid.service" ];
  #  enable = true;
  #  socketConfig = {
  #    ListenFIFO = "/home/pzuser/pzserver/zomboid.control";
  #    FileDescriptorName = "control";
  #    RemoveOnStop = true;
  #    SocketMode = "0660";
  #    SocketUser = "pzuser";
  #  };
  #};

  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    wget
    ripgrep
    binutils
    #unstable.mythtv
    tmux
    htop
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  programs.steam.enable = true;

  virtualisation.docker.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.X11Forwarding = true;

  services.valheim = {
    enable = true;
    serverName = "Testiservu";
    worldName = "savulahti";
    openFirewall = true;
    password = "vittujotain";
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  networking.firewall = {
    enable = false;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ 16261 ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}
