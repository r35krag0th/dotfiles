function ggl -d "Pull current branch from origin"
    if test (count $argv) -eq 0
        echo -e "\033[38;5;35m◖\033[38;5;234m\033[48;5;35m\033[1m Fetching and Pulling \033[0m\033[38;5;35m◗\033[0m"
        echo ""
        git fetch -pPt && git pull -pt
    else
        echo -e "\033[38;5;35m◖\033[38;5;234m\033[48;5;35m\033[1m Pulling origin $argv \033[0m\033[38;5;35m◗\033[0m"
        echo ""
        git pull origin (git_current_branch) $argv
    end
end
