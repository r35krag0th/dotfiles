function gunwipall -d "Undo all work-in-progress commits"
    while git log -n 1 | grep -q -c "\-\-wip\-\-"
        git reset HEAD~1
    end
end
