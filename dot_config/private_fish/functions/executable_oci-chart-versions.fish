# List all versions of an OCI Helm chart
# Usage: oci-chart-versions oci://registry.r35.network/charts-datadog/synthetics-private-location
#    or: oci-chart-versions registry.r35.network/charts-datadog/synthetics-private-location
function oci-chart-versions -d "List all versions of an OCI Helm chart"
    if test (count $argv) -eq 0
        echo "Usage: oci-chart-versions <oci-chart-url>"
        echo "Example: oci-chart-versions oci://registry.r35.network/charts/my-chart"
        return 1
    end

    set -l repo (string replace -r '^oci://' '' $argv[1])
    oras repo tags $repo | sort -V
end
