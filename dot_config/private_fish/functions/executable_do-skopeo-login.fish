function do-skopeo-login
    set -l vault_uuid tbtdpo4plk3dnsmlo5j7zqzhoi
    set -l harbor_uuid pcvcjgvck557xsdps2icpopoqa
    set target_uuid ""

    switch $argv[1]
        case harbor
            set target_uuid $harbor_uuid
        case gitlab
            # This uses a different process
            glab auth status \
                -t \
                --hostname gitlab.r35.dev 2>&1 \
                | rg 'Token found:' \
                | cut -d: -f2 \
                | tr -d ' \n' \
                | skopeo login registry.r35.dev -u r35krag0th --password-stdin
            return
        case github
            gh auth token \
                | skopeo login ghcr.io -u r35krag0th --password-stdin
            return
        case '*'
            echo "What registry?"
            echo " - harbor"
            echo " - gitlab"
            echo " - github"
            return
    end

    if test -z "$target_uuid"
        echo "didn't find a target UUID"
    end

    skopeo login \
        (op read "op://$vault_uuid/$target_uuid/hostname") \
        -u (op read "op://$vault_uuid/$target_uuid/username") \
        -p (op read "op://$vault_uuid/$target_uuid/credential")

end
