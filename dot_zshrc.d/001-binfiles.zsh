if [ -d "$HOME/bin" ]; then
    export PATH="${HOME}/bin:$PATH";
fi

if [ -d "$HOME/.local/bin" ]; then
    export PATH="${HOME}/.local/bin:$PATH";
fi

onelogin_shim_path="$HOME/workspace/personal/dotfiles-v2/lib/onelogin_shim.zsh"
[ -f "${onelogin_shim_path}" ] \
  && . ${onelogin_shim_path}
