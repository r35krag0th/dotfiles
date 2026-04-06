# Assume the gitlab-ci-terraform role for local Terragrunt development
#
# This assumes the gitlab-ci-terraform role from your SSO AdministratorAccess
# role and stores credentials in a profile for use with granted's `assume`.
#
# The gitlab-ci-terraform role provides the same permissions as CI/CD pipelines,
# ensuring local development has parity with automated deployments.

function assume-terraform --description "Assume gitlab-ci-terraform role for local Terragrunt development" --argument-names account
    if test -z "$account"
        echo "Usage: assume-terraform <account>"
        echo ""
        echo "Accounts:"
        echo "  Management  - AWS Organization management account"
        echo "  Production  - Production workloads"
        echo "  Non-Prod    - Development and staging"
        echo "  Sandbox     - Experimentation and testing"
        return 1
    end

    assume-role -p "$account:AdministratorAccess" -r ci/gitlab-ci-terraform -o "$account:TerraformCI"
end

# Completions
complete --command assume-terraform --no-files --exclusive
complete --command assume-terraform --condition "not __fish_seen_argument -a Management -a Production -a Non-Prod -a Sandbox" \
    --arguments "Management" --description "AWS Organization management account"
complete --command assume-terraform --condition "not __fish_seen_argument -a Management -a Production -a Non-Prod -a Sandbox" \
    --arguments "Production" --description "Production workloads"
complete --command assume-terraform --condition "not __fish_seen_argument -a Management -a Production -a Non-Prod -a Sandbox" \
    --arguments "Non-Prod" --description "Development and staging"
complete --command assume-terraform --condition "not __fish_seen_argument -a Management -a Production -a Non-Prod -a Sandbox" \
    --arguments "Sandbox" --description "Experimentation and testing"
