# NixOS system configuration
{ config, pkgs, lib, ... }:

{
  imports = [
    # Include the results of the hardware scan
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network configuration
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Time zone and locale
  time.timeZone = "UTC"; # Adjust to your timezone
  i18n.defaultLocale = "en_US.UTF-8";

  # X11 and desktop environment
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    # Alternative: use i3 window manager
    # windowManager.i3.enable = true;
  };

  # Audio
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # User account
  users.users.wilfried = {
    isNormalUser = true;
    description = "Wilfried AGO";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      firefox
    ];
  };

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System packages
  environment.systemPackages = with pkgs; [
    # Essential tools
    git
    curl
    wget
    vim
    neovim
    tmux
    
    # Development tools
    gcc
    gnumake
    
    # Terminal tools
    zsh
    starship
    
    # File management
    unzip
    p7zip
    
    # Network tools
    nmap
    
    # System monitoring
    btop
    fastfetch
  ];

  # Enable Docker
  virtualisation.docker.enable = true;

  # Enable SSH
  services.openssh.enable = true;

  # Firewall
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ ];

  # Enable ZSH as default shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "24.05";
}