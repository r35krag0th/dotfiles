function syncit
    # NOTE: -a is "archive mode" which is short for -rlptgoD
    #   -r => recursive
    #   -l => also transfer symlinks.  they're transferred as a standalone file.
    #   -p => preserve permissions
    #   -t => set destination `mtime` to match source on files and directories
    #   -g => set group to match source
    #   -o => set owner to match source
    #   -D => also transfer device and special files (shorthand for --devices --specials)
    #
    # NOTE: common other flags
    #   -h => human readable
    #   -H => attempt to preserve hard links
    command rsync \
        -ahHz \
        --inplace \
        --human-readable \
        --progress \
        $argv[1] $argv[2]
end
