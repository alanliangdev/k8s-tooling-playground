#!/bin/bash

# Exit immediately if a command exits with a non-zero status, treat unset variables as an error, and fail pipelines.
set -euo pipefail

# --- CONFIGURATION ---
CLUSTER_NAME="k8s-tooling-playground"
ARGO_NAMESPACE="argocd"
PROM_NAMESPACE="monitoring"
ROOT_APP_PATH="bootstrap/root-app.yaml"
ARGOCD_VERSION="v3.0.21"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Starting GitOps App-of-Apps Bootstrap...${NC}"

# Prerequisites Validation
for tool in kind kubectl helm git; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}❌ Error: $tool is not installed.${NC}"
        exit 1
    fi
done

# Infrastructure Provisioning (Kind Cluster)
if kind get clusters | grep -q "^$CLUSTER_NAME$"; then
    echo -e "${YELLOW}⚠️ Cluster exists. Skipping creation...${NC}"
else
    if [ ! -f "kind-config.yaml" ]; then
        echo -e "${YELLOW}⚠️ kind-config.yaml not found. Generating default config...${NC}"
        cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 8080
  - containerPort: 30000
    hostPort: 3000
  - containerPort: 30090
    hostPort: 9090
EOF
    fi
    kind create cluster --name $CLUSTER_NAME --config kind-config.yaml
fi

# Argo CD Installation
echo -e "${YELLOW}🐙 Installing Argo CD...${NC}"
kubectl create namespace $ARGO_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n $ARGO_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_VERSION/manifests/install.yaml

# Wait for Core Services
echo -e "${BLUE}⏳ Waiting for Argo CD components to initialise...${NC}"
kubectl wait --for=condition=available --timeout=120s deployment/argocd-server -n $ARGO_NAMESPACE
kubectl wait --for=condition=available --timeout=120s deployment/argocd-repo-server -n $ARGO_NAMESPACE

# Networking Configuration (NodePort for Host Access)
kubectl patch svc argocd-server -n $ARGO_NAMESPACE --type='json' -p='[{"op":"replace","path":"/spec/type","value":"NodePort"},{"op":"replace","path":"/spec/ports/0/nodePort","value":30080}]'

# Git Repository Auto-Detection
echo -e "${YELLOW}🔗 Detecting Git fork URL...${NC}"
USER_REPO_URL=$(git config --get remote.origin.url | sed 's/\.git//')

if [ -z "$USER_REPO_URL" ]; then
    echo -e "${RED}⚠️ Could not detect Git URL. Defaulting to local file values.${NC}"
else
    if [ ! -f "$ROOT_APP_PATH" ]; then
        echo -e "${RED}❌ Error: Root app manifest $ROOT_APP_PATH not found.${NC}"
        exit 1
    fi
    echo -e "Setting Root App to watch: ${BLUE}$USER_REPO_URL${NC}"
    if [ "$(uname)" = "Darwin" ]; then
        sed -i '' "s|repoURL:.*|repoURL: $USER_REPO_URL|g" $ROOT_APP_PATH
    else
        sed -i "s|repoURL:.*|repoURL: $USER_REPO_URL|g" $ROOT_APP_PATH
    fi
fi

# Root Application Deployment
echo -e "${YELLOW}🎯 Deploying Root Application...${NC}"
kubectl apply -f $ROOT_APP_PATH

# Resource Synchronisation
echo -e "${BLUE}⏳ Waiting for deployments to be registered...${NC}"
until kubectl get deployment/kube-prometheus-stack-operator -n $PROM_NAMESPACE &> /dev/null; do 
    sleep 5 
done

# Final Health Checks
echo -e "${BLUE}📦 Verifying Monitoring Stack health...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/kube-prometheus-stack-operator -n $PROM_NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/kube-prometheus-stack-grafana -n $PROM_NAMESPACE

# Deployment Summary
echo -e "${GREEN}--------------------------------------------------${NC}"
echo -e "${GREEN}✅ BOOTSTRAP COMPLETE!${NC}"
echo -e "${BLUE}Argo CD UI:  ${NC} https://localhost:8080"
echo -e "${BLUE}Grafana:     ${NC} http://localhost:3000 (admin/admin)"
echo -e "${BLUE}Prometheus:  ${NC} http://localhost:9090"
echo -e "${GREEN}--------------------------------------------------${NC}"
echo -n "🔑 Argo CD Password: "
kubectl -n $ARGO_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
echo -e "${GREEN}--------------------------------------------------${NC}"
