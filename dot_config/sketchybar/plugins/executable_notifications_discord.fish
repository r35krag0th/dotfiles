#!/usr/bin/env fish
# vim: ft=fish

# We rely on our little helper friend
set -l current (get-app-status-label --app "Discord" | jq -r '.StatusLabel.label')

if test -z $current
    sketchybar --set $NAME label.drawing=off \
        icon.padding_left=4 \
        icon.padding_right=0
else
    sketchybar --set $NAME label="$current" \
        label.drawing=on \
        icon.padding_left=6 \
        icon.padding_right=2
end
