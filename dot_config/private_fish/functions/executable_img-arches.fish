function img-arches --description "List image architectures"
    skopeo inspect --raw docker://$argv[1] \
        | jq -r '.manifests[].platform | "\(.architecture)/\(.os)"' \
        | sort -u
end
