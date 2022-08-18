automatic_tfswitch_via_tfswitchrc() {
    local tfswitchrc_path=".tfswitchrc"
    if [ -f "${tfswitchrc_path}" ]; then
        echo -e '🧙‍♂️🪄✨ \033[38;5;93mTF\033[38;5;56mSwitch\033[0m\033[1m|Hook\033[0m'
        tfswitch
    fi
}

add-zsh-hook chpwd automatic_tfswitch_via_tfswitchrc
