function gitwatch --description 'Watch repo LOC, status, and last 5 commits (with styled headers)'
    # File extensions to count LOC for (default: ts)
    set -l exts $argv
    if test (count $exts) -eq 0
        set exts ts
    end

    # Build a regex like: ts|tsx|js
    set -l ext_regex (string join '|' $exts)

    set -l cmd "
printf '\e[96m━━━ \e[93m📊 Lines of Code ($ext_regex) \e[96m━━━\e[0m\n\n'
git ls-files | rg '\\.($ext_regex)\$' | xargs wc -l | rg --color always 'total'
echo

printf '\e[96m━━━ \e[93m📁 Git Status \e[96m━━━\e[0m\n\n'
git -c color.status=always status -s
echo

printf '\e[96m━━━ \e[93m🕓 Last 5 Commits \e[96m━━━\e[0m\n\n'
git log -5 --color=always --pretty=format:'%C(auto)%h %C(dim)[%ar]%C(reset) %s'
"

    viddy -n 30 -- bash -lc "$cmd"
end
