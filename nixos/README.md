# NixOS Setup Guide

This guide covers setting up the NixOS version of this dotfiles repository.

## Prerequisites

- A running NixOS system
- Git installed
- Internet connection for downloading packages

## Quick Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/wilfriedago/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. **Generate hardware configuration:**
   ```bash
   sudo nixos-generate-config --show-hardware-config > nixos/hardware-configuration.nix
   ```

3. **Customize configuration:**
   - Edit `flake.nix` to update hostname and user details
   - Edit `nixos/configuration.nix` to adjust system settings
   - Edit `nixos/home.nix` to customize user packages and settings

4. **Run setup script:**
   ```bash
   ./scripts/nixos/setup.sh
   ```

## Manual Setup

If you prefer to set up manually:

1. **Enable flakes (if not already enabled):**
   ```bash
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
   ```

2. **Build system configuration:**
   ```bash
   sudo nixos-rebuild switch --flake .#nixos
   ```

3. **Install Home Manager:**
   ```bash
   nix run home-manager/master -- switch --flake .#wilfried
   ```

4. **Deploy additional dotfiles:**
   ```bash
   pip install --user dotdrop  # if not available
   dotdrop install -c dotdrop.config.yaml -p nixos --force
   ```

## Configuration Files

### System Configuration
- `nixos/configuration.nix` - Main system configuration
- `nixos/configuration-sway.nix` - Alternative with Sway window manager
- `nixos/hardware-configuration.nix` - Hardware-specific settings (generated)

### User Configuration
- `nixos/home.nix` - Home Manager configuration for user packages and settings
- `flake.nix` - Nix flake definition with inputs and outputs

### Window Managers
- `config/i3/config` - i3 window manager configuration (X11)
- `config/sway/config` - Sway window manager configuration (Wayland)

## Customization

### Adding Packages

**System packages** (requires rebuild):
```nix
# In nixos/configuration.nix
environment.systemPackages = with pkgs; [
  # Add your packages here
];
```

**User packages** (Home Manager):
```nix
# In nixos/home.nix
home.packages = with pkgs; [
  # Add your packages here
];
```

### Updating Configuration

1. **Update flake inputs:**
   ```bash
   nix flake update
   ```

2. **Rebuild system:**
   ```bash
   sudo nixos-rebuild switch --flake ~/.dotfiles#nixos
   ```

3. **Update user configuration:**
   ```bash
   home-manager switch --flake ~/.dotfiles#wilfried
   ```

### Window Manager Choice

By default, the configuration uses GNOME desktop environment. To use a tiling window manager:

1. **For i3 (X11):**
   - Uncomment i3 configuration in `nixos/configuration.nix`
   - Comment out GNOME configuration
   - Rebuild system

2. **For Sway (Wayland):**
   - Use `nixos/configuration-sway.nix` instead
   - Update flake.nix to use the Sway configuration

## Troubleshooting

### Hardware Configuration Issues
If the generated hardware configuration doesn't work:
1. Boot from NixOS installation media
2. Mount your system
3. Run `nixos-generate-config --root /mnt`
4. Copy the generated hardware configuration

### Package Not Found
- Check if the package exists: `nix search nixpkgs package-name`
- For unfree packages, enable in configuration: `nixpkgs.config.allowUnfree = true;`

### Service Startup Issues
- Check systemd status: `systemctl status service-name`
- View logs: `journalctl -u service-name`

## Differences from macOS Setup

| macOS | NixOS | Notes |
|-------|-------|-------|
| Homebrew | Nix packages | Declarative package management |
| AeroSpace | i3/Sway | Tiling window managers |
| Homebrew services | systemd | Service management |
| `~/Library/...` | `~/.config/...` | Different config paths |
| Karabiner | Built-in keybindings | Key remapping handled by WM |

## Useful Commands

```bash
# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Garbage collection
sudo nix-collect-garbage -d

# Check what packages are installed
nix-env -q

# Search for packages
nix search nixpkgs package-name
```