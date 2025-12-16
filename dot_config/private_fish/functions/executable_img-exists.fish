function img-exists --description "Check if image tag exists"
    skopeo inspect docker://$argv[1] >/dev/null 2>&1
    and echo "✔ exists"
    or echo "✘ not found"
end
