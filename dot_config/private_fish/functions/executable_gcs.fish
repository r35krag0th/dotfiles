function gcs -d "Create a GPG-signed commit"
    git commit --gpg-sign $argv
end
