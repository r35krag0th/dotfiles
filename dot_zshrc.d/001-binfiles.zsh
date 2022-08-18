if [ -d "$HOME/bin" ]; then
    export PATH="${HOME}/bin:$PATH";
fi

if [ -d "$HOME/.local/bin" ]; then
    export PATH="${HOME}/.local/bin:$PATH";
fi

. ${0:A:h}/../../lib/onelogin_shim.zsh
