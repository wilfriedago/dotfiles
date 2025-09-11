# Home Manager configuration
{ config, pkgs, inputs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "wilfried";
  home.homeDirectory = "/home/wilfried";

  # Packages that should be installed to the user profile
  home.packages = with pkgs; [
    # Development tools
    gh                      # GitHub CLI
    glab                    # GitLab CLI
    git-delta               # Better git diff
    lazygit                 # Terminal UI for git
    lazydocker              # Terminal UI for docker
    
    # Terminal utilities
    eza                     # Modern ls replacement
    fd                      # Better find
    fzf                     # Fuzzy finder
    ripgrep                 # Better grep
    bat                     # Better cat
    yazi                    # Terminal file manager
    zoxide                  # Smart cd
    jq                      # JSON processor
    
    # Network tools
    xh                      # Better curl
    
    # Development environments
    nodejs                  # Node.js
    python3                 # Python
    
    # Kubernetes tools
    kubectl                 # Kubernetes CLI
    k9s                     # Kubernetes dashboard
    
    # Infrastructure tools
    terraform               # Infrastructure as code
    vault                   # Secrets management
    
    # Monitoring
    fastfetch               # System info
    btop                    # System monitor
    
    # Text editors
    neovim                  # Modern vim
    
    # Fonts
    (nerdfonts.override { fonts = [ "Symbols" ]; })
    
    # GUI applications (if using desktop environment)
    discord
    spotify
    bitwarden
    obsidian
    vscode
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Wilfried AGO";
    userEmail = "your-email@example.com"; # Update with your email
    extraConfig = {
      core = {
        editor = "nvim";
        autocrlf = "input";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
    delta = {
      enable = true;
      options = {
        navigate = true;
        light = false;
        side-by-side = true;
      };
    };
  };

  # Zsh configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    shellAliases = {
      ll = "eza -l";
      la = "eza -la";
      lt = "eza --tree";
      cat = "bat";
      find = "fd";
      grep = "rg";
      cd = "z";
    };
    
    initExtra = ''
      # Source existing zsh configuration files
      [[ -f ~/.config/zsh/settings.zsh ]] && source ~/.config/zsh/settings.zsh
      [[ -f ~/.config/zsh/aliases.zsh ]] && source ~/.config/zsh/aliases.zsh
      [[ -f ~/.config/zsh/functions.zsh ]] && source ~/.config/zsh/functions.zsh
      [[ -f ~/.config/zsh/completions.zsh ]] && source ~/.config/zsh/completions.zsh
      
      # Initialize zoxide
      eval "$(zoxide init zsh)"
    '';
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    settings = {
      # Use existing starship configuration
      # This will be sourced from ~/.config/starship/starship.toml
    };
  };

  # Direnv for development environments
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # Tmux
  programs.tmux = {
    enable = true;
    clock24 = true;
    mouse = true;
    prefix = "C-a";
  };

  # GPG
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };

  # i3 window manager configuration (alternative to AeroSpace)
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = "Mod1"; # Alt key
      
      keybindings = {
        # Window management (similar to AeroSpace)
        "Mod1+h" = "focus left";
        "Mod1+j" = "focus down";
        "Mod1+k" = "focus up";
        "Mod1+l" = "focus right";
        
        "Mod1+Shift+h" = "move left";
        "Mod1+Shift+j" = "move down";
        "Mod1+Shift+k" = "move up";
        "Mod1+Shift+l" = "move right";
        
        # Workspaces
        "Mod1+1" = "workspace number 1";
        "Mod1+2" = "workspace number 2";
        "Mod1+3" = "workspace number 3";
        "Mod1+4" = "workspace number 4";
        "Mod1+5" = "workspace number 5";
        "Mod1+6" = "workspace number 6";
        "Mod1+7" = "workspace number 7";
        "Mod1+8" = "workspace number 8";
        "Mod1+9" = "workspace number 9";
        
        "Mod1+Shift+1" = "move container to workspace number 1";
        "Mod1+Shift+2" = "move container to workspace number 2";
        "Mod1+Shift+3" = "move container to workspace number 3";
        "Mod1+Shift+4" = "move container to workspace number 4";
        "Mod1+Shift+5" = "move container to workspace number 5";
        "Mod1+Shift+6" = "move container to workspace number 6";
        "Mod1+Shift+7" = "move container to workspace number 7";
        "Mod1+Shift+8" = "move container to workspace number 8";
        "Mod1+Shift+9" = "move container to workspace number 9";
        
        # Layout
        "Mod1+slash" = "layout toggle split";
        "Mod1+Shift+f" = "fullscreen toggle";
        
        # System
        "Mod1+Shift+c" = "reload";
        "Mod1+Shift+r" = "restart";
      };
      
      gaps = {
        inner = 0;
        outer = 0;
      };
    };
  };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
    TERMINAL = "ghostty";
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with.
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}