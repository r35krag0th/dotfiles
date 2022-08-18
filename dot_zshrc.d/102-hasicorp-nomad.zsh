if [ -x /usr/local/bin/nomad ]; then
    autoload -U +X bashcompinit && bashcompinit
    complete -o nospace -C /usr/local/bin/nomad nomad
fi
