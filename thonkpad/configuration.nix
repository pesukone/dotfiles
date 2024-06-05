# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz";
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      (import "${home-manager}/nixos")
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  # Setup keyfile
  #boot.initrd.secrets = {
  #  "/crypto_keyfile.bin" = null;
  #};

  # Enable swap on luks
  #boot.initrd.luks.devices."luks-9442067a-747f-4add-b871-0b2b1874bc9d".device = "/dev/disk/by-uuid/9442067a-747f-4add-b871-0b2b1874bc9d";
  #boot.initrd.luks.devices."luks-9442067a-747f-4add-b871-0b2b1874bc9d".keyFile = "/crypto_keyfile.bin";

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  #programs.nix-ld.enable = true;

  networking.hostName = "thonkpad"; # Define your hostname.
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

  #powerManagement.enable = true;
  services.power-profiles-daemon.enable = true;

  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    layout = "fi";
    xkbVariant = "";

    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
      config = builtins.readFile ./xmonad.hs;
    };

    deviceSection = ''
      Option "DRI" "3"
      Option "TearFree" "true"
    '';
  };

  location.provider = "manual";
  location.latitude = 60.170792;
  location.longitude = 24.934997;
  services.redshift = {
    enable = true;
    brightness = {
      day = "1";
      night = "1";
    };
    temperature = {
      day = 5500;
      night = 1850;
    };
  };

  # Configure console keymap
  console.keyMap = "fi";

  fonts.packages = with pkgs; [
    fira-code
    fira-code-symbols
  ];

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;
  hardware.enableRedistributableFirmware = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jussi = {
    isNormalUser = true;
    description = "Jussi Aalto";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      librewolf
      thunderbird
      nodePackages.prettier
      gimp
      stack
      #ghc
      (haskell-language-server.override { supportedGhcVersions = [ "94" ]; })
      gnome.ghex
      yt-dlp
      calibre
      microsoft-edge
      discord
    ];
  };

  home-manager.users.jussi = {
    home.stateVersion = "23.11";
    programs.vim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [
        coc-nvim
        coc-json
        coc-prettier
        coc-tsserver
        coc-java
        coc-rust-analyzer
      ];
      settings = {
        ignorecase = true;
        smartcase = true;
        background = "dark";
      };
      extraConfig = ''
        set shell=/bin/sh
        set encoding=utf-8
        set ttymouse=sgr

        set nobackup
        set nowritebackup

        set updatetime=300
        set signcolumn=yes

        inoremap <silent><expr> <TAB>
          \ coc#pum#visible() ? coc#pum#next(1) :
          \ CheckBackspace() ? "\<Tab>" :
          \ coc#refresh()
        inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

        inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
          \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

        function! CheckBackspace() abort
          let col = col('.') - 1
          return !col || getline('.')[col - 1]  =~# '\s'
        endfunction

        inoremap <silent><expr> <c-@> coc#refresh()

        nnoremap <silent> K :call ShowDocumentation()<CR>
        function! ShowDocumentation()
          if CocAction('hasProvider', 'hover')
            call CocActionAsync('doHover')
          else
            call feedkeys('K', 'in')
          endif
        endfunction

        autocmd CursorHold * silent call CocActionAsync('highlight')

        set statusline^=%{coc#status()}%{get(b:,'coc_current_function',\'\')}

        filetype plugin indent on
      '';
    };
    home.file.".vim/coc-settings.json".source = ./coc-settings.json;

    xdg.configFile."xmonad/xmonad.hs".source = ./xmonad.hs;
    xdg.configFile."xmobar/xmobarrc".source = ./xmobarrc.hs;
    xdg.configFile."kitty/kitty.conf".source = ./kitty.conf;
    #xdg.configFile."picom.conf".source = ./picom.conf;
    home.file.".stalonetrayrc".source = ./stalonetrayrc;

    programs.bash = {
      enable = true;
      shellAliases = {
        rg = "rg --smart-case";
      };
      bashrcExtra = ''
        eval "$(direnv hook bash)"
      '';
    };
    programs.git = {
      enable = true;
      userName = "pesukone";
      userEmail = "j.v.aalto@gmail.com";
    };
    programs.mpv = {
      enable = true;
      config = {
        fullscreen = true;
        profile = "gpu-hq";
        hwdec = "auto";
        ytdl-format = "(bestvideo[height<=?1080][vcodec^=vp09]/bestvideo)+bestaudio/best";
        save-position-on-quit = true;
        demuxer-max-bytes = "8GiB";
        demuxer-max-back-bytes = "2GiB";
        stop-screensaver = true;
      };
    };
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    # Bump swc version
    (final: prev: {
      swc = prev.rustPlatform.buildRustPackage {
        pname = "swc";
        version = "0.91.25";

        src = prev.fetchCrate {
          pname = "swc_cli";
          version = "0.91.25";
          sha256 = "sha256-oJo9ktCUMREWJiF+wKHHJGc0m/RE0Vb4L6uXBSVKHT8=";
        };

        cargoSha256 = "sha256-q3YXZMyza339STbS4tQbQ6npkQCXdV40yiCDPQsQa1Y=";

        buildFeatures = [ "swc_core/plugin_transform_host_native" ];

        meta = with prev.lib; {
          description = "Rust-based platform for the Web";
          homepage = "https://github.com/swc-project/swc";
          license = licenses.asl20;
          maintainers = with maintainers; [ dit7ya ];
        };
      };
    })
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    slack
    gitFull
    nodejs
    python3
    ripgrep
    bash-completion
    bashInteractive
    tree
    gnumake
    cmake
    gcc
    clang-tools
    glibc
    htop
    virt-manager
    zip
    unzip
    file
    haskellPackages.xmobar
    dmenu
    nitrogen
    picom
    xorg.xsetroot
    xscreensaver
    networkmanagerapplet
    stalonetray
    surf
    xorg.xev
    pulseaudio
    brightnessctl
    feh
    kitty
    blueman
    pa_applet
    direnv
    autorandr
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # For slack screen sharing
  xdg = {
    portal = {
      enable = true;
      #extraPortals = with pkgs; [
      #  xdg-desktop-portal-wlr
      #  xdg-desktop-portal-gtk
      #];
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true;
  programs.java.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}
