function gcssm -d "Create a GPG-signed commit with signoff and message"
    git commit --gpg-sign --signoff --message $argv
end
