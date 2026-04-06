function start-notes-devserver -d "Start Docusaurus Dev Server for Notes"
    set -l session_name docusaurus-notes
    set -l tmux_bin (which tmux)

    echo -e "\033[1;33m-->\033[0m Checking for session '$session_name'..."
    if command $tmux_bin has-session -t $session_name 2>/dev/null
        echo -e "\033[1;31m>>>\033[0m Session '$session_name' already exists..."
    else
        echo -e "\033[1;33m-->\033[0m Going to $HOME/notes..."
        cd $HOME/notes

        echo -e "\033[1;33m-->\033[0m Staritng session '$session_name'"
        command $tmux_bin -2 -u new -s $session_name -d -- npm start

        echo -e "\033[1;32m<<<\033[0m Done!"
    end

    echo ""
    tmux-ls-pretty
end
