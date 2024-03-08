# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  dbus-sway-environment = pkgs.writeTextFile {
    name = "dbus-sway-environment";
    destination = "/bin/dbus-sway-environment";
    executable = true;

    text = ''
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
      systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
      systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr
    '';
  };

  configure-gtk = pkgs.writeTextFile {
    name = "configure-gtk";
    destination = "/bin/configure-gtk";
    executable = true;
    text = let
      schema = pkgs.gsettings-desktop-schemas;
      datadir = "${schema}/share/gsettings-schemas/${schema.name}";
    in ''
      export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
      gnome_schema=org.gnome.desktop.interface
      gsettings set $gnome_schema gtk-theme 'Dracula'
    '';
  };

  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-23.11.tar.gz";

in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      (import "${home-manager}/nixos")
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  boot.initrd.kernelModules = [ "amdgpu" ];

  boot.extraModulePackages = [ config.boot.kernelPackages.rtl88xxau-aircrack ];
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="FI" 
    options kvm_amd nested=1
  '';
  hardware.wirelessRegulatoryDatabase = true;

  networking.hostName = "htpc"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager = {
    enable = true;
    wifi.scanRandMacAddress = false;
  };

  # Set your time zone.
  time.timeZone = "Europe/Helsinki";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.utf8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fi_FI.utf8";
    LC_IDENTIFICATION = "fi_FI.utf8";
    LC_MEASUREMENT = "fi_FI.utf8";
    LC_MONETARY = "fi_FI.utf8";
    LC_NAME = "fi_FI.utf8";
    LC_NUMERIC = "fi_FI.utf8";
    LC_PAPER = "fi_FI.utf8";
    LC_TELEPHONE = "fi_FI.utf8";
    LC_TIME = "fi_FI.utf8";
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "fi";
    xkbVariant = "";
    enable = true;
    displayManager = {
      gdm.enable = true;
      autoLogin = {
        enable = true;
        user = "jussi";
      };
    };
    desktopManager.gnome.enable = true;
  };

  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Configure console keymap
  console.keyMap = "fi";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jussi = {
    isNormalUser = true;
    description = "Jussi Aalto";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" ];
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    htop
    wget
    nixos-generators
    tmux
    firefox
    alacritty
    #dbus-sway-environment
    #configure-gtk
    wayland
    xdg-utils
    glib
    dracula-theme
    gnome3.adwaita-icon-theme
    swaylock
    swayidle
    grim
    slurp
    wl-clipboard
    bemenu
    mako
    wdisplays
    pavucontrol
  ];

/*
  environment.gnome.excludePackages = (with pkgs; [
  ]) ++ (with pkgs.gnome; [
    gnome-remote-desktop
  ]);
*/

  services.gnome.gnome-remote-desktop.enable = false;

  home-manager.users.jussi = {
    home.stateVersion = "23.11";
    
    #wayland.windowManager.sway = {
    #  enable = true;
    #  config = rec {
    #    modifier = "Mod1";
    #    terminal = "alacritty";
    #    startup = [
    #      {command = "firefox";}
    #    ];
    #  };
    #};

    #programs.bash = {
    #  enable = true;
    #  profileExtra = ''
    #    if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
    #      exec sway
    #    fi
    #  '';
    #};
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  programs.steam = {
   enable = true;
  };
  hardware.opengl.driSupport32Bit = true;

  #programs.sway.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  #services.getty.autologinUser = "jussi";

  services.pipewire = {
    enable = false;
    alsa.enable = true;
    pulse.enable = true;
  };
  hardware.pulseaudio = {
    enable = true;
    extraConfig = "load-module module-combine-sink";
  };

  services.dbus.enable = true;
  #xdg.portal = {
  #  enable = true;
  #  wlr.enable = true;
  #  extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  #};

  security.polkit.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

  virtualisation.libvirtd = {
    enable = true;
    onShutdown = "suspend";
    onBoot = "start";
    qemu.package = pkgs.qemu_kvm;
  };
}
