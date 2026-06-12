function _pwgen_usage
    echo -e "\033[1;32mpwgen\033[0m [flags]"
    echo ""
    echo -e "\033[1;31m-h/--help\033[0m     show usage"
    echo -e "\033[1;36m-s/--size\033[0m     bytes of input before encoding"
    echo -e "\033[1;35m-b/--base64\033[0m   output a base64-encoded binary value"
    echo ""
end

function pwgen --description "Generates passwords"
    argparse h/help "s/size=" b/base64 -- $argv

    if set -ql _flag_h
        _pwgen_usage
        return
    end

    set -ql _flag_s
    and set -l pw_length $_flag_s

    set -l format_flag -hex
    set -ql _flag_b
    and set -l format_flag -base64

    command openssl rand $format_flag $pw_length
end
