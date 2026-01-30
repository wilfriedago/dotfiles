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

# =============================================================================================
# Environment variables
# =============================================================================================
export ANDROID_HOME="${HOME}/Library/Android/sdk"

# Check if Android SDK is installed
if [[ ! -d "$ANDROID_HOME" ]]; then
  return
fi

# Add SDK tools to PATH
case ":$PATH:" in
  *":$ANDROID_HOME/platform-tools:"*) ;;
  *) export PATH="${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${PATH}" ;;
esac
