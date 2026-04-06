function gfgl -d "Force pull current branch from origin"
    echo -e "\033[38;5;35m◖\033[38;5;234m\033[48;5;35m\033[1m Force Fetching and Pulling \033[0m\033[38;5;35m◗\033[0m"
    echo ""
    git fetch -pPt --force && git pull -pt
end
