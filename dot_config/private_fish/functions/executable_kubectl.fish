function kubectl --wraps=kubectl --description 'kubectl via kubecolor with color'
    command kubecolor --force-colors $argv
end
