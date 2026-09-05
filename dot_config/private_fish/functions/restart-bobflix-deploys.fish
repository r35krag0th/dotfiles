function restart-bobflix-deploys
    for deploy_name in (kubectl get deploy -n bobflix -o name)
        echo ""
        echo -e "\033[1;33m>>> \033[1;32mRestarting\033[0m $deploy_name"
        kubecolor rollout restart $deploy_name -n bobflix
    end
end
