# Get the last N versions of an OCI Helm chart (default: 5)
# Usage: oci-chart-recent oci://registry.r35.network/charts-datadog/synthetics-private-location [count]
function oci-chart-recent -d "Get the last N versions of an OCI Helm chart"
    if test (count $argv) -eq 0
        echo "Usage: oci-chart-recent <oci-chart-url> [count]"
        echo "Example: oci-chart-recent oci://registry.r35.network/charts/my-chart 10"
        return 1
    end

    set -l repo (string replace -r '^oci://' '' $argv[1])
    set -l n 5
    if test (count $argv) -ge 2
        set n $argv[2]
    end

    oras repo tags $repo | sort -V | tail -$n
end
