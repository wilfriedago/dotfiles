# Alternative NixOS configuration with Sway (Wayland)
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network configuration
  networking.hostName = "nixos-sway";
  networking.networkmanager.enable = true;

  # Time zone and locale
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # Wayland and Sway
  security.polkit.enable = true;
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock
      swayidle
      swaybg
      waybar
      rofi-wayland
      grim # Screenshot tool
      slurp # Screen area selection
      wl-clipboard # Clipboard utilities
      brightnessctl # Brightness control
      playerctl # Media player control
    ];
  };

  # XDG Desktop Portal
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
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
    extraGroups = [ "networkmanager" "wheel" "docker" "video" "audio" ];
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
    
    # Wayland specific
    wayland
    wayland-utils
    
    # Terminal
    ghostty
    
    # Development
    gcc
    gnumake
    
    # System monitoring
    btop
    fastfetch
  ];

  # Fonts
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "Symbols" ]; })
  ];

  # Enable Docker
  virtualisation.docker.enable = true;

  # Enable SSH
  services.openssh.enable = true;

  # ZSH
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # This value determines the NixOS release
  system.stateVersion = "24.05";
}