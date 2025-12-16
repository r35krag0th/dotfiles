function img-tags-picker --description "Interactively pick a tag for an image"
    if test (count $argv) -lt 1
        echo "Usage: img-tags-picker <image>"
        return 1
    end

    img-tags $argv[1] | fzf --height 40% --reverse
end
