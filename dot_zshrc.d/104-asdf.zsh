[ -d "${HOME}/.asdf" ] \
    && [ -f "${HOME}/.asdf/asdf.zsh" ] \
    && . $HOME/.asdf/asdf.sh

function install_asdf_plugin() {
    # $1 Plugin
    # $2 Version
    # $3 Make Global Version
    local checkmark="✅"
    local lightningbolt="⚡"
    local eyes="👀"
    local star="🌟"
    local diamond="💎"
    local wavy_dash="〰"
    local divider="${wavy_dash}"
    checkmark="${checkmark} "
    lightningbolt="${lightningbolt} "
    diamond="${diamond} "
    eyes="${eyes} "
    star="${star} "

    # Make a 20-wide divider to make this visually appealing
    for i in {1..20}; do
        divider="${divider}${wavy_dash}"
    done

    local plugin_name="${1}"
    local plugin_version="${2}"
    local make_global_version="${3}"

    echo ""
    echo -e "${diamond} \033[1mInstalling asdf plugin '${plugin_name}'\033[0m ${diamond}"
    echo ""

    echo -e "\033[1;36m${divider}\033[0m"

    echo ""
    echo -e "${eyes} \033[32mAdding\033[0m \033[1m${plugin_name}\033[0m"
    echo ""
    asdf plugin add $1
    echo ""
    echo -e "${checkmark} \033[32mAdding\033[0m is complete"

    echo ""
    echo -e "\033[36m${divider}\033[0m"

    echo ""
    if [ -z "${plugin_version}" ]; then
        echo -e "${star} \033[35mUsing\033[0m \033[1mLATEST\033[0m version"
        plugin_version="latest"
    else
        echo -e "${star} \033[35mUsing\033[0m version: \033[1m${plugin_version}\033[0m"
    fi

    echo ""
    echo -e "\033[36m${divider}\033[0m"

    echo ""
    echo -e "${star} \033[32mInstalling\033[0m \033[1m${plugin_name}\033[0m \033[36m${plugin_version}\033[0m"
    echo ""
    asdf install $plugin_name $plugin_version

    echo ""
    echo -e "\033[36m${divider}\033[0m"

    case $make_global_version in
        yes|y|1)
            if [ "${plugin_version}" = "latest" ]; then
                plugin_version=$(asdf latest $plugin_name)
            fi
            echo ""
            echo -e "${star} \033[32mSetting\033[0m global version to \033[1m${plugin_version}\033[0m"
            asdf global $plugin_name $plugin_version
            ;;
        *)
            ;;
    esac

    echo ""
    echo "${checkmark} Complete!"
}
