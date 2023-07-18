
{ config, pkgs, lib, ... }:

let
  user = "pi";
  password = "raspberry";
  SSID = "mywifi";
  SSIDpassword = "mypassword";
  interface = "wlan0";
  hostname = "raspi";
in {
  imports = ["${fetchTarball "https://github.com/NixOS/nixos-hardware/archive/936e4649098d6a5e0762058cb7687be1b2d90550.tar.gz" }/raspberry-pi/4"];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    "/export/pool" = {
      device = "/dev/disk/by-uuid/cdb281b2-1650-4430-ad8a-25ca64d7a09d";
      fsType = "btrfs";
      options = [ "compress=zstd" ];
    };
  };

  networking = {
    hostName = hostname;
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 111 2049 4000 4001 4002 20048 ];
      allowedUDPPorts = [ 111 2049 4000 4001 4002 20048 ];
    };
    #wireless = {
    #  enable = true;
    #  networks."${SSID}".psk = SSIDpassword;
    #  interfaces = [ interface ];
    #};
  };

  services.nfs.server = {
    enable = true;
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
    exports = ''
      /export 		192.168.50.0/24(insecure,rw,sync,no_subtree_check,crossmnt,fsid=0)
      /export/pool 	192.168.50.0/24(insecure,rw,sync,no_subtree_check)
    '';
  };

  environment.systemPackages = with pkgs; [
    vim
    htop
    wget
    btrfs-progs
  ];

  services.openssh.enable = true;

  users = {
    mutableUsers = false;
    users."${user}" = {
      isNormalUser = true;
      password = password;
      extraGroups = [ "wheel" ];
    };
  };

  # Enable GPU acceleration
  #hardware.raspberry-pi."4".fkms-3d.enable = true;

  services.xserver = {
    layout = "fi";
    #enable = true;
    #displayManager.lightdm.enable = true;
    #desktopManager.xfce.enable = true;
  };

  console.useXkbConfig = true;

  #hardware.pulseaudio.enable = true;

  system.stateVersion = "22.05";
}
