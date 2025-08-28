if test -d /opt/homebrew/opt/curl/bin
    # If you need to have curl first in your PATH, run:
    fish_add_path /opt/homebrew/opt/curl/bin
    # For compilers to find curl you may need to set:
    set -gx LDFLAGS "$LDFLAGS -L/opt/homebrew/opt/curl/lib"
    set -gx CPPFLAGS "$LDFLAGS -I/opt/homebrew/opt/curl/include"
    # For pkg-config to find curl you may need to set:
    # set -gx PKG_CONFIG_PATH /opt/homebrew/opt/curl/lib/pkgconfig
end
