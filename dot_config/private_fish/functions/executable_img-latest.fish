function img-latest --description "Get highest semver tag"
    img-tags $argv[1] \
        | rg '^\d+\.\d+\.\d+' \
        | sort -V \
        | tail -n 1
end
