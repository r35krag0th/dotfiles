function gwt --description "Interactive git worktree switcher"
    set -l root (git rev-parse --show-toplevel 2>/dev/null)
    or begin
        echo "Not in a git repository"
        return 1
    end

    set -l rows
    for line in (git worktree list)
        set -l wt_path (string match -rg '^(\S+)' -- $line)
        set -l branch (string match -rg '\[([^\]]+)\]' -- $line)

        set -l display
        if test "$wt_path" = "$root"
            set display (printf '\033[38;5;220m\033[1m  \033[38;5;38mprimary\033[0m \033[38;5;242m(%s)\033[m' $branch)
        else if test -n "$branch"
            set display (printf '\033[38;5;140m\033[1m   %s\033[0m \033[38;5;242m(%s)\033[m' (basename $wt_path) $branch)
        else
            set display (printf '\033[38;5;140m\033[1m   %s\033[0m \033[38;5;242m(detached)\033[m' (basename $wt_path))
        end

        set -a rows (printf '%s\t%s' $wt_path $display)
    end

    set -l selected (printf '%s\n' $rows | fzf --with-nth 2 --delimiter \t --height 50% --ansi)
    test -n "$selected" || return 1
    cd (string split -f1 \t -- $selected)
end
