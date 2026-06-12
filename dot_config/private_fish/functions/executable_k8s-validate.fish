function k8s-validate --description "runs kubeconform on all yaml files recursively, or on args you pass in."
  argparse -- $argv
  # `NormalizedKubernetesVersion` - Kubernetes version, prefixed by `v` -- `v1.33`
  # `StrictSuffix` - Either `-strict` or `""` depending on the `-strict` flag on kubeconform
  # `ResourceKind` - Kind of the Kubernetes resource
  # `ResourceAPIVersion` - Version of the API being used for the resource
  # `Group` - Version
  # `KindSuffix` - suffix compute from the apiVersion
  # ==========================================================
  # NOTE: Order matters here.  The SchemaStore.org lines need to be absolutely last.
  set schema_location_flags -schema-location 'https://schemas.r35.dev/r35/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
    -schema-location 'https://schemas.r35.dev/crds/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
    -schema-location 'https://schemas.r35.dev/kubernetes/1.33/{{.ResourceKind}}{{.KindSuffix}}.json' \
    -schema-location 'https://www.schemastore.org/kustomization.json'

  if test (count $argv) -lt 1
    kubeconform \
      $schema_location_flags \
      **/*.yaml *.yaml
    return
  end

  kubeconform \
    $schema_location_flags \
    $argv
end
