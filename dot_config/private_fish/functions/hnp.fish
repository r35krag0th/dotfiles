function _pill_shape
    set pill_color "$argv[1]m"
    echo -ne "\033[38;5;$pill_color\033[0m\033[48;5;$pill_color\033[38;5;231m$argv[2]\033[0m\033[38;5;$pill_color\033[0m"
end

function hnp --description "Create a new Herdr Pane"
    argparse --exclusive 'd,u,l,r' d/down u/up l/left r/right -- $argv
    or return

    set direction down
    if set -ql _flag_u
        set direction up
    else if set -ql _flag_l
        set direction left
    else if set -ql _flag_r
        set direction right
    end

    set result (herdr pane split --current --direction $direction --cwd "$PWD" --no-focus)
    set pane_id (echo $result | jq -r '.result.pane.pane_id')
    set tab_id (echo $result | jq -r '.result.pane.tab_id')
    set workspace_id (echo $result | jq -r '.result.pane.workspace_id')

    echo -ne "Created pane "
    _pill_shape 54 $pane_id
    echo -ne " in tab "
    _pill_shape 30 $tab_id
    echo -ne " in workspace "
    _pill_shape 125 $workspace_id
    echo ""
end
