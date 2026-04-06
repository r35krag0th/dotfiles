if command -v mise >/dev/null
    command mise completion fish | source
    fish_add_path ~/.local/share/mise/shims/
end
