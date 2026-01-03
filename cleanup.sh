#!/bin/bash
CLUSTER_NAME="k8s-tooling-playground"

echo "🗑️ Deleting $CLUSTER_NAME..."
kind delete cluster --name $CLUSTER_NAME

# Optional: Clean up any local temporary files or kubeconfig contexts
kubectl config delete-context kind-$CLUSTER_NAME 2>/dev/null
echo "✅ Cleanup complete."
