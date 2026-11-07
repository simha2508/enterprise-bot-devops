
#!/usr/bin/env bash

set -euo pipefail

# Project root directory
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

CLUSTER_NAME="demo"
IMAGE_NAME="enterprise-bot:1.0.0"
NAMESPACE="demo"
RELEASE_NAME="demo"

INGRESS_MANIFEST="https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.14.1/deploy/static/provider/kind/deploy.yaml"

echo "======================================"
echo " Starting Enterprise Bot setup"
echo "======================================"

# Check required tools
for tool in docker kind kubectl helm; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "ERROR: Required tool '$tool' is not installed."
        exit 1
    fi
done

# Check Docker daemon
docker info >/dev/null

# Create or reuse Kind cluster
if kind get clusters | grep -qx "$CLUSTER_NAME"; then
    echo "Kind cluster '$CLUSTER_NAME' already exists. Reusing it."
else
    echo "Creating Kind cluster '$CLUSTER_NAME'..."
    kind create cluster \
        --name "$CLUSTER_NAME" \
        --config "$ROOT_DIR/kind-config.yaml"
fi

kubectl config use-context "kind-$CLUSTER_NAME"

# Install NGINX Ingress Controller
echo "Installing NGINX Ingress Controller..."
kubectl apply -f "$INGRESS_MANIFEST"

echo "Waiting for Ingress Controller..."
kubectl rollout status deployment/ingress-nginx-controller \
    -n ingress-nginx \
    --timeout=600s

# Build application image
echo "Building Docker image..."
docker build -t "$IMAGE_NAME" "$ROOT_DIR/service"

# Load image into Kind
echo "Loading image into Kind..."
kind load docker-image "$IMAGE_NAME" --name "$CLUSTER_NAME"

# Create namespace if it does not exist
echo "Ensuring namespace '$NAMESPACE' exists..."
kubectl create namespace "$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

# Install or upgrade Helm release
echo "Deploying application using Helm..."
helm upgrade --install "$RELEASE_NAME" "$ROOT_DIR/chart" \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --wait \
    --timeout 5m

# Verify application deployment
echo "Waiting for application deployment..."
kubectl rollout status deployment/demo-app \
    -n "$NAMESPACE" \
    --timeout=300s

echo "======================================"
echo " Setup completed successfully!"
echo "======================================"

echo "Current application resources:"
kubectl get pods,svc,ingress -n "$NAMESPACE"
