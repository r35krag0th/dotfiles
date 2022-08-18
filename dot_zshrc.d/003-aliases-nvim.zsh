# This is left to be very simple because I don't want to exec "which" on each
# new shell because it really slows down the launch time.
#
# This works with the assumption that you are using the scripts/setup-vim.zsh
# to do everything.  Which that would automatically detect NeoVim being
# installed.
#
# 2020-09-16: rename init.vim -> init-original.vim; init_new.vim -> init.vim
alias vim="nvim -p"
export EDITOR="nvim"
