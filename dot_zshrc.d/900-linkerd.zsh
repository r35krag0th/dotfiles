if [ -f "${HOME}/.linkerd2/bin/linkerd" ]; then
    # export PATH=$PATH:/home/bobsaska/.linkerd2/bin
    if [ -d "${HOME}/.oh-my-zsh" ]; then
        if [ ! -f "${ZSH_COMPLETION_DIR}/_linkerd" ]; then
            linkerd completion zsh > "${ZSH_COMPLETION_DIR}/_linkerd"
        fi
    else
        source <(linkerd completion zsh)
    fi
    compinit
fi
