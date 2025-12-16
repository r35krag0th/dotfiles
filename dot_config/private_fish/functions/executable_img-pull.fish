function img-pull --description "Pick a tag and pull it"
    set image $argv[1]
    set tag (img-tags-fzf $image)
    test -n "$tag"; and docker pull "$image:$tag"
end
