#!/usr/bin/env bash

set -e

# NixOS system configuration script
# This script applies NixOS configuration and Home Manager settings

echo "Configuring your NixOS system. This may take a while..."

# Check if we're running on NixOS
if ! command -v nixos-rebuild &> /dev/null; then
    echo "Error: This script is designed for NixOS systems"
    echo "Make sure you're running this on a NixOS installation"
    exit 1
fi

# Navigate to the dotfiles directory
DOTFILES_DIR="$HOME/.dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Error: Dotfiles directory not found at $DOTFILES_DIR"
    echo "Please clone the repository to ~/.dotfiles first"
    exit 1
fi

cd "$DOTFILES_DIR"

# Enable flakes if not already enabled
if ! nix show-config | grep -q "experimental-features.*flakes"; then
    echo "Enabling Nix flakes..."
    mkdir -p ~/.config/nix
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
fi

# Generate hardware configuration if it doesn't exist
if [ ! -f "nixos/hardware-configuration.nix" ]; then
    echo "Generating hardware configuration..."
    sudo nixos-generate-config --show-hardware-config > nixos/hardware-configuration.nix
fi

# Build and switch to the new configuration
echo "Building and applying NixOS configuration..."
sudo nixos-rebuild switch --flake .#nixos

# Apply Home Manager configuration
echo "Applying Home Manager configuration..."
nix run home-manager/master -- switch --flake .#wilfried

# Set up symlinks for existing dotfiles that aren't managed by Nix
echo "Setting up additional dotfiles with dotdrop..."
if command -v dotdrop &> /dev/null; then
    dotdrop install -c dotdrop.config.yaml -p nixos --force
else
    echo "Warning: dotdrop not found. Installing with pip..."
    pip install --user dotdrop
    dotdrop install -c dotdrop.config.yaml -p nixos --force
fi

echo "NixOS configuration applied successfully!"
echo "Please log out and log back in for all changes to take effect."
echo ""
echo "To rebuild the system configuration after changes:"
echo "  sudo nixos-rebuild switch --flake ~/.dotfiles#nixos"
echo ""
echo "To update Home Manager configuration:"
echo "  home-manager switch --flake ~/.dotfiles#wilfried"