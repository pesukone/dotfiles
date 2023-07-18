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

  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
  };

  #hardware.deviceTree = {
  #  base = pkgs.device-tree_rpi;
  #  overlays = [ "${pkgs.device-tree_rpi.overlays}/vc4-fkms-v3d.dtbo" ];
  #};

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  networking = {
    hostName = hostname;
    networkmanager = {
      enable = true;
    };
    #wireless = {
    #  enable = true;
    #  networks."${SSID}".psk = SSIDpassword;
    #  interfaces = [ interface ];
    #};
  };

  environment.systemPackages = with pkgs; [
    vim
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

  system.stateVersion = "22.05";
}
