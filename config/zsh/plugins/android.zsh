# =============================================================================================
# ~/.config/zsh/plugins/android.zsh
# =============================================================================================
# Android SDK Zsh Plugin
# This plugin provides environment setup for the Android SDK.
#
# It configures ANDROID_HOME and adds SDK tools to PATH.
# For docs and more info, see: https://github.com/wilfriedago/dotfiles
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Variables
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_EMULATOR="$ANDROID_HOME/emulator"
export ANDROID_TOOLS="$ANDROID_HOME/tools"
export ANDROID_PLATFORM_TOOLS="$ANDROID_HOME/platform-tools"

# Add SDK tools to PATH
case ":$PATH:" in
  *":$ANDROID_EMULATOR:"*) ;;
  *":$ANDROID_TOOLS:"*) ;;
  *":$ANDROID_PLATFORM_TOOLS:"*) ;;
  *) export PATH="$ANDROID_EMULATOR:$ANDROID_TOOLS:$ANDROID_PLATFORM_TOOLS:${PATH}" ;;
esac
