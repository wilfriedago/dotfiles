# =============================================================================================
# ~/.config/zsh/plugins/vite-plus.zsh
# =============================================================================================
# Vite+ Zsh Plugin
# Vite+ (vp) owns the JavaScript toolchain: the Node.js runtime and the npm, pnpm, yarn and
# bun shims. mise owns everything else and is told to ignore JS tools (config/mise).
#
# PATH and the `vp` wrapper are set up in zprofile, right after Homebrew. This file only adds
# what an interactive shell needs on top: completions for `vp` and `vpr`.
#
# Global defaults (Node.js version, shim modes) live in ~/.config/vite-plus/config.json,
# which is versioned in this repo. Change them with `vp env default <version>`.
# For docs and more info, see: https://viteplus.dev/guide/env
# =============================================================================================
# License: MIT Copyright (c) 2025 Wilfried Kirin AGO <https://wilfriedago.me>
# =============================================================================================

# Guards
(( $+commands[vp] )) || return

# Non-login shells inherit PATH but not functions; restore the `vp` wrapper so
# `vp env use` can still change the current shell.
(( $+functions[vp] )) || [[ ! -r "$XDG_CONFIG_HOME/vite-plus/env" ]] || source "$XDG_CONFIG_HOME/vite-plus/env"

# Completion — cached for faster startup. Completion is dynamic (the script calls back
# into vp), so the cache only needs refreshing when the binary changes.
_cache_eval "vite-plus" "VP_COMPLETE=zsh command vp" "${commands[vp]:A}"

# `vpr` is `vp run`: complete it as such. Mirrors the snippet in the generated env file.
_vpr_complete() {
  local -a orig=("${words[@]}")
  if [[ "${orig[2]-}" == "-C" ]]; then
    if (( ${#orig[@]} >= 4 )); then
      words=("vp" "-C" "${orig[3]}" "run" "${orig[@]:3}")
      (( CURRENT >= 4 )) && CURRENT=$((CURRENT + 1))
    else
      words=("vp" "${orig[@]:1}")
    fi
  elif [[ "${orig[2]-}" == -C?* ]]; then
    if (( ${#orig[@]} >= 3 )); then
      words=("vp" "${orig[2]}" "run" "${orig[@]:2}")
      (( CURRENT >= 3 )) && CURRENT=$((CURRENT + 1))
    else
      words=("vp" "${orig[@]:1}")
    fi
  else
    words=("vp" "run" "${orig[@]:1}")
    (( CURRENT >= 2 )) && CURRENT=$((CURRENT + 1))
  fi
  ${=_comps[vp]}
}
compdef _vpr_complete vpr
