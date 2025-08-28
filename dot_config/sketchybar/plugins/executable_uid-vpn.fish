#!/usr/bin/env fish
# vim: ft=fish
set -l vpn_service_uuid 655B8DFD-3D86-4D86-907C-82B0FFC64564
set -l status_first_line (scutil --nc status "$vpn_service_uuid" | head -n 1)
set -l connected_text Connected

set -l connected_icon ""
set -l disconnected_icon ""

set -l used_icon ""
set -l used_label VPN

set -l icon_color 0xFFFFFFFF
set -l label_color 0xFFFFFFFF
set -l background_and_border_color 0xFF000000

if [ "$status_first_line" = "$connected_text" ]
    set used_icon $connected_icon
    # set icon_color 0xFFDBF227 #DBF227
    set icon_color 0xFF9FC131 #9FC131
    # set icon_color 0xFF267365 #267365
    set label_color 0xFFDBF227 #DBF227
    # set label_color 0xFFD6D58E #D6D58E
    set background_and_border_color 0xFF267365 #267365
else
    set used_icon $disconnected_icon
    set icon_color 0xFFF23030 #F23030
    set label_color 0xFFD6D58E #D6D58E
end

# echo "[uid-vpn] icon=$used_icon"
# echo "[uid-vpn] label=$used_label"
# echo "[uid-vpn] icon.color=$icon_color"
# echo "[uid-vpn] label.color=$label_color"
# echo "[uid-vpn] background.color=$background_and_border_color"
# echo "[uid-vpn] background.border_color=$background_and_border_color"

sketchybar --set "$NAME" \
    icon="$used_icon" \
    label="$used_label" \
    icon.color="$icon_color" \
    label.color="$label_color" \
    label.padding_right=8 \
    background.drawing=on \
    background.color="$background_and_border_color" \
    background.border_color="$background_and_border_color" \
    background.border_width=2 \
    background.corner_radius=8 \
    background.height=26
