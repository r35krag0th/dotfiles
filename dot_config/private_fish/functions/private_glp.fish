function glp -d "Show pretty commit log with author names"
    git log --pretty=format:"%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [%cn]" --decorate $argv
end
