# Loop through every API resource and dump its data in JSON format
for resource in $(kubectl api-resources --verbs=list --namespaced=false -o name); do
  echo "Fetching cluster-scoped: $resource"
  kubectl get "$resource" -o json 2>/dev/null
done

for resource in $(kubectl api-resources --verbs=list --namespaced=true -o name); do
  echo "Fetching namespaced: $resource"
  kubectl get "$resource" --all-namespaces -o json 2>/dev/null
done
