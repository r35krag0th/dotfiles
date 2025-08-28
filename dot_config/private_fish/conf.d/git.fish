# Oh My Zsh Git Plugin - Fish Shell Conversion
# Save this file as ~/.config/fish/conf.d/git_plugin.fish
# or source it from your config.fish file

# Helper functions for branch detection

function git_current_branch -d "Get the current git branch name"
    if git rev-parse --git-dir >/dev/null 2>&1
        git branch --show-current 2>/dev/null
    end
end

function git_main_branch -d "Detect and return the main branch (main, master, etc.)"
    if not git rev-parse --git-dir >/dev/null 2>&1
        return 1
    end

    for ref in refs/heads/main refs/heads/trunk refs/heads/mainline refs/heads/default refs/heads/stable refs/heads/master
        if git show-ref -q --verify $ref
            echo (basename $ref)
            return 0
        end
    end

    echo master
    return 1
end

function git_develop_branch -d "Detect and return the development branch (dev, develop, etc.)"
    if not git rev-parse --git-dir >/dev/null 2>&1
        return 1
    end

    for branch in dev devel develop development
        if git show-ref -q --verify refs/heads/$branch
            echo $branch
            return 0
        end
    end

    echo develop
    return 1
end

# WIP (Work in Progress) functions
function gwip -d "Create a work-in-progress commit with all changes"
    git add -A
    git rm (git ls-files --deleted) 2>/dev/null
    git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"
end

function gunwip -d "Undo the last work-in-progress commit"
    git log -n 1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1
end

function gunwipall -d "Undo all work-in-progress commits"
    while git log -n 1 | grep -q -c "\-\-wip\-\-"
        git reset HEAD~1
    end
end

# Branch management functions
function grename -d "Rename a branch locally and on remote"
    if test (count $argv) -ne 2
        echo "Usage: grename <old_branch> <new_branch>"
        return 1
    end

    set old_branch $argv[1]
    set new_branch $argv[2]

    git branch -m $old_branch $new_branch
    if git config --get branch.$old_branch.remote >/dev/null
        git push origin :$old_branch
        git push --set-upstream origin $new_branch
    end
end

function ggpnp -d "Pull from and push to origin for current branch"
    if test (count $argv) -eq 0
        ggl && ggp
    else
        ggl $argv && ggp $argv
    end
end

function gbda -d "Delete all merged branches except main/master/develop"
    git branch --no-color --merged | command grep -vE "^(\+|\*|\s*(master|main|develop|dev)\s*\$)" | command xargs -n 1 git branch -d
end

function gbdall -d "Force delete all branches except main/master/develop"
    git branch --no-color | command grep -vE "^(\+|\*|\s*(master|main|develop|dev)\s*\$)" | command xargs -n 1 git branch -D
end

function ggsup -d "Set upstream for current branch to origin"
    git branch --set-upstream-to=origin/(git_current_branch)
end

function ggpull -d "Pull from origin for current branch"
    git pull origin (git_current_branch)
end

function ggpush -d "Push current branch to origin"
    git push origin (git_current_branch)
end

function gtl -d "List tags matching a pattern"
    git tag --sort=-v:refname -n --list "$argv[1]*"
end

# Basic Git functions
function g -d "Git command shortcut"
    git $argv
end

function ga -d "Add files to staging area"
    git add $argv
end

function gaa -d "Add all files to staging area"
    git add --all $argv
end

function gapa -d "Add files interactively (patch mode)"
    git add --patch $argv
end

function gau -d "Add only modified files to staging area"
    git add --update $argv
end

function gav -d "Add files with verbose output"
    git add --verbose $argv
end

function gap -d "Apply a patch file"
    git apply $argv
end

function gapt -d "Apply a patch with 3-way merge"
    git apply --3way $argv
end

# Branch functions
function gb -d "List or create branches"
    git branch $argv
end

function gba -d "List all branches (local and remote)"
    git branch --all $argv
end

function gbd -d "Delete a branch"
    git branch --delete $argv
end

function gbD -d "Force delete a branch"
    git branch --delete --force $argv
end

function gbl -d "Show who changed each line in a file"
    git blame -w $argv
end

function gbnm -d "List branches not merged into current branch"
    git branch --no-merged $argv
end

function gbr -d "List remote branches"
    git branch --remote $argv
end

function gbs -d "Start git bisect session"
    git bisect $argv
end

function gbsb -d "Mark current commit as bad in bisect"
    git bisect bad $argv
end

function gbsg -d "Mark current commit as good in bisect"
    git bisect good $argv
end

function gbsn -d "Mark current commit as new in bisect"
    git bisect new $argv
end

function gbso -d "Mark current commit as old in bisect"
    git bisect old $argv
end

function gbsr -d "Reset bisect session"
    git bisect reset $argv
end

function gbss -d "Start bisect with bad and good commits"
    git bisect start $argv
end

# Commit functions
function gc -d "Create a commit with verbose output"
    git commit --verbose $argv
end

function gc! -d "Amend the last commit"
    git commit --verbose --amend $argv
end

function gca -d "Commit all tracked changes"
    git commit --verbose --all $argv
end

function gca! -d "Amend commit with all tracked changes"
    git commit --verbose --all --amend $argv
end

function gcan! -d "Amend commit without editing message"
    git commit --verbose --all --no-edit --amend $argv
end

function gcans! -d "Amend commit with signoff, no edit"
    git commit --verbose --all --signoff --no-edit --amend $argv
end

function gcam -d "Commit all changes with message"
    git commit --all --message $argv
end

function gcsm -d "Commit with signoff and message"
    git commit --signoff --message $argv
end

function gcas -d "Commit all changes with signoff"
    git commit --all --signoff $argv
end

function gcasm -d "Commit all changes with signoff and message"
    git commit --all --signoff --message $argv
end

function gcs -d "Create a GPG-signed commit"
    git commit --gpg-sign $argv
end

function gcss -d "Create a GPG-signed commit with signoff"
    git commit --gpg-sign --signoff $argv
end

function gcssm -d "Create a GPG-signed commit with signoff and message"
    git commit --gpg-sign --signoff --message $argv
end

function gcf -d "List git configuration"
    git config --list $argv
end

function gcl -d "Clone a repository with submodules"
    git clone --recurse-submodules $argv
end

function gclean -d "Clean untracked files interactively"
    git clean --interactive -d $argv
end

function gpristine -d "Reset to HEAD and clean all untracked files"
    git reset --hard && git clean --force -d $argv
end

# Checkout functions
function gco -d "Switch to a different branch or commit"
    git checkout $argv
end

function gcb -d "Create and switch to a new branch"
    git checkout -b $argv
end

function gcor -d "Checkout with recursive submodule update"
    git checkout --recurse-submodules $argv
end

function gcd -d "Switch to the development branch"
    git checkout (git_develop_branch) $argv
end

function gcm -d "Switch to the main branch"
    git checkout (git_main_branch) $argv
end

# Cherry-pick functions
function gcp -d "Apply changes from another commit"
    git cherry-pick $argv
end

function gcpa -d "Abort current cherry-pick operation"
    git cherry-pick --abort $argv
end

function gcpc -d "Continue cherry-pick after resolving conflicts"
    git cherry-pick --continue $argv
end

# Diff functions
function gd -d "Show changes between commits, working tree, etc."
    git diff $argv
end

function gdca -d "Show staged changes"
    git diff --cached $argv
end

function gdcw -d "Show staged changes word by word"
    git diff --cached --word-diff $argv
end

function gdct -d "Show the most recent tag"
    git describe --tags (git rev-list --tags --max-count=1) $argv
end

function gds -d "Show staged changes (alias for gdca)"
    git diff --staged $argv
end

function gdt -d "Show files changed in a commit"
    git diff-tree --no-commit-id --name-only -r $argv
end

function gdw -d "Show changes word by word"
    git diff --word-diff $argv
end

# Fetch functions
function gf -d "Fetch changes from remote"
    git fetch $argv
end

function gfa -d "Fetch all remotes and prune deleted branches"
    git fetch --all --prune --jobs=10 $argv
end

function gfo -d "Fetch changes from origin"
    git fetch origin $argv
end

# Log functions
function glog -d "Show commit history as a graph"
    git log --oneline --decorate --graph $argv
end

function gloga -d "Show all commit history as a graph"
    git log --oneline --decorate --graph --all $argv
end

function glol -d "Show pretty commit log with relative dates"
    git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' $argv
end

function glols -d "Show pretty commit log with stats"
    git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --stat $argv
end

function glod -d "Show pretty commit log with absolute dates"
    git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset' $argv
end

function glods -d "Show pretty commit log with short dates"
    git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset' --date=short $argv
end

function glola -d "Show pretty commit log for all branches"
    git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --all $argv
end

function glo -d "Show one-line commit history"
    git log --oneline --decorate $argv
end

function glg -d "Show commit history with file statistics"
    git log --stat $argv
end

function glgp -d "Show commit history with patches"
    git log --stat --patch $argv
end

function glgg -d "Show commit history as a graph"
    git log --graph $argv
end

function glgga -d "Show all branches commit history as a graph"
    git log --graph --decorate --all $argv
end

function glgm -d "Show last 10 commits as a graph"
    git log --graph --max-count=10 $argv
end

function gll -d "Show abbreviated commit history as a graph"
    git log --graph --pretty=oneline --abbrev-commit $argv
end

function glp -d "Show pretty commit log with author names"
    git log --pretty=format:"%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [%cn]" --decorate $argv
end

# Merge functions
function gm -d "Merge branches"
    git merge $argv
end

function gma -d "Abort current merge"
    git merge --abort $argv
end

function gmom -d "Merge from origin main branch"
    git merge origin/(git_main_branch) $argv
end

function gmod -d "Merge from origin development branch"
    git merge origin/(git_develop_branch) $argv
end

function gmtl -d "Run merge tool to resolve conflicts"
    git mergetool --no-prompt $argv
end

function gmtlvim -d "Run vimdiff merge tool to resolve conflicts"
    git mergetool --no-prompt --tool=vimdiff $argv
end

function gmu -d "Merge without fast-forward"
    git merge --no-ff $argv
end

# Push/Pull functions  
function gl -d "Pull changes from remote"
    git pull $argv
end

function gup -d "Pull with rebase"
    git pull --rebase $argv
end

function gupa -d "Pull with rebase and autostash"
    git pull --rebase --autostash $argv
end

function gupav -d "Pull with rebase, autostash, and verbose output"
    git pull --rebase --autostash --verbose $argv
end

function gupv -d "Pull with rebase and verbose output"
    git pull --rebase --verbose $argv
end

function ggu -d "Pull current branch from origin with rebase"
    git pull --rebase origin (git_current_branch) $argv
end

function ggl -d "Pull current branch from origin"
    git pull origin (git_current_branch) $argv
end

function ggpur -d "Pull current branch from origin with rebase"
    git pull --rebase origin (git_current_branch) $argv
end

function gp -d "Push changes to remote"
    git push $argv
end

function gpd -d "Show what would be pushed (dry run)"
    git push --dry-run $argv
end

function gpf -d "Force push with lease (safer force push)"
    git push --force-with-lease $argv
end

function gpf! -d "Force push (dangerous, overwrites remote)"
    git push --force $argv
end

function gpoat -d "Push all branches and tags to origin"
    git push origin --all && git push origin --tags $argv
end

function gpr -d "Pull with rebase"
    git pull --rebase $argv
end

function gpu -d "Push to upstream remote"
    git push upstream $argv
end

function gpv -d "Push with verbose output"
    git push --verbose $argv
end

function ggp -d "Push current branch to origin"
    git push origin (git_current_branch) $argv
end

# Rebase functions
function grb -d "Rebase current branch"
    git rebase $argv
end

function grba -d "Abort current rebase"
    git rebase --abort $argv
end

function grbc -d "Continue rebase after resolving conflicts"
    git rebase --continue $argv
end

function grbd -d "Rebase current branch onto development branch"
    git rebase (git_develop_branch) $argv
end

function grbi -d "Start interactive rebase"
    git rebase --interactive $argv
end

function grbm -d "Rebase current branch onto main branch"
    git rebase (git_main_branch) $argv
end

function grbo -d "Rebase onto a specific commit"
    git rebase --onto $argv
end

function grbs -d "Skip current commit during rebase"
    git rebase --skip $argv
end

# Remote functions
function gr -d "Manage remote repositories"
    git remote $argv
end

function gra -d "Add a remote repository"
    git remote add $argv
end

function grh -d "Reset current branch to a specific commit"
    git reset $argv
end

function grhh -d "Hard reset current branch (loses changes)"
    git reset --hard $argv
end

function groh -d "Hard reset current branch to origin"
    git reset origin/(git_current_branch) --hard $argv
end

function grm -d "Remove files from git and filesystem"
    git rm $argv
end

function grmc -d "Remove files from git but keep on filesystem"
    git rm --cached $argv
end

function grmv -d "Rename a remote"
    git remote rename $argv
end

function grrm -d "Remove a remote"
    git remote remove $argv
end

function grset -d "Set URL for a remote"
    git remote set-url $argv
end

function grss -d "Restore files from a specific source"
    git restore --source $argv
end

function grst -d "Unstage files (restore from staging)"
    git restore --staged $argv
end

function grt -d "Go to git repository root directory"
    cd (git rev-parse --show-toplevel; or echo .) $argv
end

function gru -d "Reset (unstage) specific files"
    git reset -- $argv
end

function grup -d "Update all remotes"
    git remote update $argv
end

function grv -d "Show remote repositories with URLs"
    git remote --verbose $argv
end

# Show functions
function gsh -d "Show information about commits, tags, etc."
    git show $argv
end

function gsps -d "Show commit with signature verification"
    git show --pretty=short --show-signature $argv
end

# Stash functions
function gsta -d "Save current changes to stash"
    git stash push $argv
end

function gstaa -d "Apply most recent stash"
    git stash apply $argv
end

function gstc -d "Clear all stashes"
    git stash clear $argv
end

function gstd -d "Drop a specific stash"
    git stash drop $argv
end

function gstl -d "List all stashes"
    git stash list $argv
end

function gstp -d "Apply and remove most recent stash"
    git stash pop $argv
end

function gsts -d "Show contents of a stash"
    git stash show --text $argv
end

function gstu -d "Stash including untracked files"
    git stash push --include-untracked $argv
end

function gstall -d "Stash all files including ignored ones"
    git stash push --all $argv
end

# Status functions
function gss -d "Show short git status"
    git status --short $argv
end

function gst -d "Show git status"
    git status $argv
end

# Submodule functions
function gsm -d "Manage git submodules"
    git submodule $argv
end

function gsma -d "Add a git submodule"
    git submodule add $argv
end

function gsmi -d "Initialize git submodules"
    git submodule init $argv
end

function gsms -d "Show git submodule status"
    git submodule status $argv
end

function gsmu -d "Update git submodules"
    git submodule update $argv
end

# Switch functions (Git 2.23+)
function gsw -d "Switch to a branch (modern alternative to checkout)"
    git switch $argv
end

function gswc -d "Create and switch to a new branch"
    git switch --create $argv
end

function gswd -d "Switch to the development branch"
    git switch (git_develop_branch) $argv
end

function gswm -d "Switch to the main branch"
    git switch (git_main_branch) $argv
end

# Tag functions
function gts -d "Create a signed tag"
    git tag --sign $argv
end

function gta -d "Create an annotated tag"
    git tag --annotate $argv
end

function gtv -d "List tags sorted by version"
    git tag | sort -V $argv
end

# Index functions
function gignore -d "Mark files as assumed unchanged"
    git update-index --assume-unchanged $argv
end

function gunignore -d "Unmark files as assumed unchanged"
    git update-index --no-assume-unchanged $argv
end

# Worktree functions
function gwt -d "Manage git worktrees"
    git worktree $argv
end

function gwta -d "Add a new git worktree"
    git worktree add $argv
end

function gwtls -d "List all git worktrees"
    git worktree list $argv
end

function gwtmv -d "Move a git worktree"
    git worktree move $argv
end

function gwtrm -d "Remove a git worktree"
    git worktree remove $argv
end

# Whatchanged function
function gwch -d "Show what changed in commits with patches"
    git whatchanged -p --abbrev-commit --pretty=medium $argv
end

# Special GUI functions
function gk -d "Launch gitk GUI for all branches"
    gitk --all --branches $argv &
end

function gke -d "Launch gitk GUI for reflog commits"
    gitk --all (git log --walk-reflogs --pretty=%h) $argv &
end
