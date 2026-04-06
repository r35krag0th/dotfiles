function gke -d "Launch gitk GUI for reflog commits"
    gitk --all (git log --walk-reflogs --pretty=%h) $argv &
end
