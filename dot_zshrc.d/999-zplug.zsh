if [ -d "${HOME}/.zplug" ]; then
    source ~/.zplug/init.zsh

    zplug "wfxr/forgit"
    zplug "denysdovhan/spaceship-prompt", use:spaceship.zsh, from:github, as:theme

    # Install plugins if there are plugins that have not been installed
    if ! zplug check --verbose; then
        printf "Install? [y/N]: "
        if read -q; then
            echo; zplug install
        fi
    fi

    zplug load --verbose
fi
