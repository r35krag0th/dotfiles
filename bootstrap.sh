#!/usr/bin/env zsh

base_directory=${0:a:h}
source ${base_directory}/lib/logging.zsh

install_file() {
    # $1 = source (without ./files prefix)
    # $2 = destination
    # $3 = mode (0600)
    local target_mode=${3:-0600}
    step_line "Installing" "${1} --> ${2}"
    echo install -m ${target_mode} files/${1} ${2}
}

# Install Files
install_file "gitconfig" "$HOME/.gitconfig"
