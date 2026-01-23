function timoni-login-gitlab
    echo "Logging in to registry.r35.dev..."
    echo ""
    glab auth status -t --hostname gitlab.r35.dev 2>&1 \
        | rg 'Token found:' \
        | cut -d: -f2 \
        | tr -d ' \n' \
        | timoni registry login registry.r35.dev -u r35krag0th --password-stdin
end
