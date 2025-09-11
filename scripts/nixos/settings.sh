#!/usr/bin/env bash

set -e

# NixOS system settings configuration
# This script configures various system settings for NixOS

echo 'Configuring NixOS system settings...'

# === Fonts ===
echo "Installing additional fonts..."
fc-cache -fv

# === Git Configuration ===
echo "Configuring Git..."
# Git configuration is handled by Home Manager, but we can set global defaults here
if [ ! -f ~/.gitconfig ]; then
    echo "Warning: Git configuration not found. It should be managed by Home Manager."
fi

# === Shell Configuration ===
echo "Setting up shell environment..."
# Ensure zsh is the default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Changing default shell to zsh..."
    chsh -s "$(which zsh)"
fi

# === Development Environment ===
echo "Setting up development environment..."

# Create common development directories
mkdir -p ~/Projects
mkdir -p ~/Scripts
mkdir -p ~/.local/bin

# === SSH Configuration ===
echo "Setting up SSH..."
if [ ! -d ~/.ssh ]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
fi

# === GPG Configuration ===
echo "Setting up GPG..."
if [ ! -d ~/.gnupg ]; then
    mkdir -p ~/.gnupg
    chmod 700 ~/.gnupg
fi

# === Docker Configuration ===
echo "Setting up Docker..."
# Add user to docker group if not already added
if ! groups $USER | grep -q docker; then
    echo "Adding user to docker group..."
    sudo usermod -aG docker $USER
    echo "Please log out and log back in for docker group changes to take effect"
fi

# === Flatpak Setup (if available) ===
if command -v flatpak &> /dev/null; then
    echo "Setting up Flatpak..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# === XDG Directories ===
echo "Setting up XDG directories..."
mkdir -p ~/.local/share/applications
mkdir -p ~/.local/share/fonts
mkdir -p ~/.local/share/icons
mkdir -p ~/.config
mkdir -p ~/.cache

# === Terminal Configuration ===
echo "Configuring terminal settings..."
# Set up terminal-specific configurations
if command -v gsettings &> /dev/null; then
    # GNOME Terminal settings
    gsettings set org.gnome.desktop.default-applications.terminal exec 'ghostty'
    
    # Set dark theme
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    
    # Set monospace font
    gsettings set org.gnome.desktop.interface monospace-font-name 'Symbols Nerd Font Mono 11'
fi

# === Firewall Configuration ===
echo "Configuring firewall..."
# Basic firewall rules (this requires sudo)
if command -v ufw &> /dev/null; then
    sudo ufw --force enable
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
fi

echo "NixOS system settings configuration completed!"
echo "Some changes may require a reboot to take effect."