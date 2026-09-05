function aide-check-link --description "Check .aide/bin/aide points at the installed aide plugin binary"
    argparse h/help f/fix q/quiet -- $argv
    or return 2

    if set -q _flag_help
        echo "Usage: aide-check-link [--fix] [--quiet] [PROJECT_ROOT]"
        echo
        echo "Verifies <PROJECT_ROOT>/.aide/bin/aide (default: \$HOME) resolves to the"
        echo "aide binary belonging to the currently installed Claude Code plugin."
        echo
        echo "  -f, --fix    repoint the symlink when it has drifted"
        echo "  -q, --quiet  suppress output when nothing needs doing (drift and"
        echo "               repairs are still reported) - intended for hooks"
        echo "  -h, --help   show this help"
        echo
        echo "Exit codes: 0 = up to date, 1 = drift, 2 = cannot determine"
        return 0
    end

    # An empty argv[1] is normal from a hook whose \$CLAUDE_PROJECT_DIR is unset.
    set -l root $HOME
    if test (count $argv) -gt 0; and test -n "$argv[1]"
        set root $argv[1]
    end

    # Never conjure a .aide/ store where none exists. The aide binary itself
    # refuses to do this without a .aide or .git marker "to avoid polluting
    # arbitrary dirs" (cmd/aide/main.go); a --fix hook must respect the same
    # boundary or it would litter every project it starts in.
    if not test -d $root/.aide
        set -q _flag_quiet
        or echo "skip  no .aide store at $root"
        return 0
    end

    set -l link $root/.aide/bin/aide
    set -l manifest $HOME/.claude/plugins/installed_plugins.json

    command -q jq
    or begin
        echo "aide-check-link: jq is required" >&2
        return 2
    end

    test -f $manifest
    or begin
        echo "aide-check-link: no plugin manifest at $manifest" >&2
        return 2
    end

    # installed_plugins.json is what Claude Code actually loaded, which is more
    # authoritative than picking the highest-numbered dir under plugins/cache.
    set -l install_path (jq -r '.plugins."aide@aide"[0].installPath // empty' $manifest)
    set -l install_ver (jq -r '.plugins."aide@aide"[0].version // empty' $manifest)

    test -n "$install_path"
    or begin
        echo "aide-check-link: aide plugin not listed in $manifest" >&2
        return 2
    end

    set -l expected $install_path/bin/aide
    test -x $expected
    or begin
        echo "aide-check-link: plugin binary missing or not executable: $expected" >&2
        return 2
    end

    # `version` is on the CLI fast path in cmd/aide/main.go: it returns before
    # ensureBinSymlink() runs, so probing a binary here cannot rewrite the very
    # symlink we are measuring.
    set -l want_ver ($expected version 2>/dev/null | string match -rg 'version (\S+)')
    set -l expected_real (realpath $expected 2>/dev/null)

    set -l problems

    if not test -L $link
        if test -e $link
            set -a problems "$link is a regular file, not a symlink"
        else
            set -a problems "$link does not exist"
        end
    else if not test -e $link
        set -a problems "symlink is broken (dangling target)"
    else
        set -l actual (realpath $link 2>/dev/null)
        set -l have_ver ($link version 2>/dev/null | string match -rg 'version (\S+)')

        # Path and version are checked independently on purpose: a stale plugin
        # dir can hold a freshly downloaded binary (0.1.15/bin/.aide-version
        # containing v0.1.16), so matching one proves nothing about the other.
        test "$actual" = "$expected_real"
        or set -a problems "target is $actual"

        test "$have_ver" = "$want_ver"
        or set -a problems "linked binary reports $have_ver, plugin ships $want_ver"
    end

    if test (count $problems) -eq 0
        set -q _flag_quiet
        or begin
            echo (set_color green)"ok"(set_color normal)"  aide $want_ver"
            echo "    $link -> $expected_real"
        end
        return 0
    end

    # Drift and repairs are always reported, even under --quiet: a hook that
    # silently rewrites a symlink is exactly the invisible mutation to avoid.
    echo (set_color yellow)"drift"(set_color normal)" $link"
    for p in $problems
        echo "    - $p"
    end
    echo "    expected: $expected_real (plugin $install_ver)"

    if set -q _flag_fix
        mkdir -p (dirname $link)
        and ln -sfn $expected_real $link
        and echo (set_color green)"fixed"(set_color normal)" -> "(realpath $link)
        and return 0

        echo "aide-check-link: failed to repoint symlink" >&2
        return 2
    end

    echo "    run: aide-check-link --fix"
    return 1
end
