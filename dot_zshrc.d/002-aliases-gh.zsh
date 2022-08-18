which gh 2>&1 >/dev/null

if [ $? -eq 0 ]; then
    alias issues="gh issue"                 # Shorthand wrapper for "gh" (npm) tool
    alias prs="gh pull-requests"            # Shorthand wrapper for "gh" (npm) tool
fi
