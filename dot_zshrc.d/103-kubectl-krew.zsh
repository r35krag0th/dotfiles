#!/usr/bin/env zsh

if [ -d "${HOME}/.krew" ]; then
    export PATH="${PATH}:${HOME}/.krew/bin"
fi
