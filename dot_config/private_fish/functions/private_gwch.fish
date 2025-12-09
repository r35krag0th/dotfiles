function gwch -d "Show what changed in commits with patches"
    git whatchanged -p --abbrev-commit --pretty=medium $argv
end
