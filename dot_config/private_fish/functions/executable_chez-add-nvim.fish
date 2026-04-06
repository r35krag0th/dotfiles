function chez-add-nvim
    command chezmoi add \
        ~/.config/nvim/lazy* \
        ~/.config/nvim/lua/plugins/*.lua \
        ~/.config/nvim/lua/r35
end
