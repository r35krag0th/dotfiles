function gcss -d "Create a GPG-signed commit with signoff"
    git commit --gpg-sign --signoff $argv
end
