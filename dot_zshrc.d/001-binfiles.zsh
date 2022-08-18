if [ -d "$HOME/bin" ]; then
    export PATH="${HOME}/bin:$PATH";
fi

if [ -d "$HOME/.local/bin" ]; then
    export PATH="${HOME}/.local/bin:$PATH";
fi

[ -f $HOME/workspace/personal/dotfiles-v2/lib/onelogin_shim.zsh ] \
  && . ${0:A:h}/../../lib/onelogin_shim.zsh
