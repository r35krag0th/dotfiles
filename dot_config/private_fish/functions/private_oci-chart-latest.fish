# Get the latest version of an OCI Helm chart
# Usage: oci-chart-latest oci://registry.r35.network/charts-datadog/synthetics-private-location
function oci-chart-latest -d "Get the latest version of an OCI Helm chart"
    if test (count $argv) -eq 0
        echo "Usage: oci-chart-latest <oci-chart-url>"
        echo "Example: oci-chart-latest oci://registry.r35.network/charts/my-chart"
        return 1
    end

    set -l repo (string replace -r '^oci://' '' $argv[1])
    oras repo tags $repo | sort -V | tail -1
end
