#!/bin/bash

# Exit immediately if any command fails, treating unassigned variables as errors
set -euo pipefail

echo "=================================================="
echo -e "\n Checking the status of VKS Supervisor Service"
echo "=================================================="
vks_version=$(kubectl get pkgi svc-tkg.vsphere.vmware.com -n vmware-system-supervisor-services -ocustom-columns='VKS-SUPERVISOR-SERVICE-NAME:.metadata.name,VKS-VERSION:.status.version')
echo "$vks_version"

echo "=================================================="
echo -e "\nChecking the Compatible Kubernetes Releases for this VKS Supervisor Service"
echo "=================================================="
kubectl get kr -o json | jq '.items[] | select(.status.conditions[] | .type == "Ready" and .status == "True") | .metadata.name'


echo "=================================================="
echo -e "\n Checking the status of Clusters across all vSphere namespaces"
echo "=================================================="

# 1. Get a list of all namespaces, skipping the header row
namespaces=$(kubectl get namespaces --no-headers -o custom-columns=":metadata.name")

# 2. Iterate through each namespace
for ns in $namespaces; do
    # echo -e "\nChecking namespace: \033[1;34m$ns\033[0m"
    
    # 3. Get non-running or problematic pods in the current namespace
    # Filters out 'Running' and 'Completed' statuses
    all_clusters=$(kubectl get clusters -n "$ns" --no-headers 2>/dev/null)
        if [[ -z "$all_clusters" ]]; then
            continue 2   # Exits inner loop if no clusters found
        fi
    bad_clusters=$(kubectl get clusters -n "$ns" --no-headers | grep -v -E "True" || true)
    good_clusters=$(kubectl get clusters -n "$ns" --no-headers | grep -v -E "False" || true)
    
    if [ -z "$bad_clusters" ]; then
        echo -e "\nNamespace: \033[1;34m$ns\033[0m"
        echo -e "✅ All clusters are healthy."
        echo "$good_clusters"
    else
        echo -e "\nNamespace: \033[1;34m$ns\033[0m"
        echo -e "⚠️ Found unhealthy clusters:"
        echo "$bad_clusters"
    fi
done

echo -e "\n=================================================="
echo "Supervisor / VKS Cluster health check completed!"