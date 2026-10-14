#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# --- Usage Instructions ---
show_usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

A utility script to query the Kubernetes API server, discover all active resource 
types, and dump the entire cluster state into a valid multi-document YAML stream.

Options:
  -c, --clean    Strip out runtime cluster-assigned metadata fields (e.g., uid, 
                 resourceVersion, managedFields, status). Use this when creating 
                 blueprints meant to be restored or applied to another cluster.
  -h, --help     Show this help message and exit.

Requirements:
  - A configured 'kubectl' context pointing to your target cluster.
  - The 'jq' utility installed on your system (only required if using --clean).

Examples:
  # Export raw cluster state exactly as it exists
  ./$(basename "$0") > raw-backup.yaml

  # Export a cleaned blueprint ready for restore
  ./$(basename "$0") --clean > clean-backup.yaml
EOF
}

# --- Argument Parsing ---
CLEAN_FIELDS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--clean)
      CLEAN_FIELDS=true
      shift
      ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    *)
      echo "Error: Unknown option '$1'" >&2
      show_usage >&2
      exit 1
      ;;
  esac
done

# --- Dependency & Context Checks ---
if ! command -v kubectl &> /dev/null; then
  echo "Error: 'kubectl' command not found. Please install it and try again." >&2
  exit 1
fi

if [ "$CLEAN_FIELDS" = true ] && ! command -v jq &> /dev/null; then
  echo "Error: '--clean' requires the 'jq' utility. Please install 'jq' or run without the flag." >&2
  exit 1
fi

# Ensure kubectl can talk to a cluster before starting
if ! kubectl cluster-info &> /dev/null; then
  echo "Error: Cannot connect to the Kubernetes cluster. Check your kubeconfig context." >&2
  exit 1
fi

# --- Core Logic ---
JQ_FILTER='
  del(
    .items[].metadata.uid,
    .items[].metadata.resourceVersion,
    .items[].metadata.generation,
    .items[].metadata.creationTimestamp,
    .items[].metadata.managedFields,
    .status
  )
'

# Fetch and export all cluster-scoped resources
for resource in $(kubectl api-resources --verbs=list --namespaced=false -o name); do
  echo "--- Fetching cluster-scoped: $resource ---" >&2
  
  if [ "$CLEAN_FIELDS" = true ]; then
    # Fetch as JSON, use jq to strip internal fields, then convert back to YAML via kubectl
    kubectl get "$resource" --ignore-not-found -o json 2>/dev/null | jq "$JQ_FILTER" | kubectl convert -f - -o yaml 2>/dev/null || true
  else
    kubectl get "$resource" --ignore-not-found -o yaml 2>/dev/null
  fi
done

# Fetch and export all namespaced resources across all namespaces
for resource in $(kubectl api-resources --verbs=list --namespaced=true -o name); do
  echo "--- Fetching namespaced: $resource ---" >&2
  
  if [ "$CLEAN_FIELDS" = true ]; then
    kubectl get "$resource" --all-namespaces --ignore-not-found -o json 2>/dev/null | jq "$JQ_FILTER" | kubectl convert -f - -o yaml 2>/dev/null || true
  else
    kubectl get "$resource" --all-namespaces --ignore-not-found -o yaml 2>/dev/null
  fi
done
