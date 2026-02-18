function docker-login-gitlab
    echo "Logging in to registry.r35.dev..."
    echo ""
    set --local auth_token (
    glab auth status -t --hostname gitlab.r35.dev 2>&1 \
        | rg 'Token found:' \
        | cut -d: -f2 \
        | tr -d ' \n'
  )
    echo "Doing Docker Login"
    echo $auth_token | docker login registry.r35.dev -u r35krag0th --password-stdin

    echo ""
    echo "Doing Skopeo Login"
    echo $auth_token | skopeo login registry.r35.dev -u r35krag0th --password-stdin
end
