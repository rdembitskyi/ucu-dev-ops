#!/bin/bash

# Blue-Green deployment script with Kustomize

OLD_VERSION=$1
VERSION=$2

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 v1"
    exit 1
fi

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Deploying version: $VERSION"

NAMESPACE="todo-app"
OVERLAY_PATH="k8s/deployments/overlays/${VERSION}"

# Check if overlay exists
if [ ! -d "$OVERLAY_PATH" ]; then
    echo "Error: Overlay for version $VERSION not found at $OVERLAY_PATH"
    echo "Available versions:"
    ls k8s/deployments/overlays/
    exit 1
fi

# Get AWS Account ID for image substitution
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Using AWS Account ID: $AWS_ACCOUNT_ID"

# Deploy new version using kustomize with envsubst for variable substitution
echo "Deploying version $VERSION using kustomize..."
kubectl kustomize $OVERLAY_PATH | envsubst | kubectl apply -f -

# Wait for new deployments to be ready
echo "Waiting for backend-${VERSION} to be ready..."
kubectl rollout status deployment/backend-${VERSION} -n $NAMESPACE --timeout=30s

echo "Waiting for frontend-${VERSION} to be ready..."
kubectl rollout status deployment/frontend-${VERSION} -n $NAMESPACE --timeout=30s

# Switch traffic by updating service selectors
echo "Switching traffic to version $VERSION..."
kubectl patch service backend -n $NAMESPACE -p "{\"spec\":{\"selector\":{\"app\":\"backend\",\"version\":\"${VERSION}\"}}}"
kubectl patch service frontend -n $NAMESPACE -p "{\"spec\":{\"selector\":{\"app\":\"frontend\",\"version\":\"${VERSION}\"}}}"

echo "Traffic switched to version $VERSION"

# Clean up old deployments if they exist
if [ ! -z "$OLD_VERSION" ] && [ "$OLD_VERSION" != "$VERSION" ]; then
    echo "Removing old deployments (version $OLD_VERSION)..."
    kubectl delete deployment backend-${OLD_VERSION} -n $NAMESPACE --ignore-not-found=true
    kubectl delete deployment frontend-${OLD_VERSION} -n $NAMESPACE --ignore-not-found=true
    echo "Old version $OLD_VERSION cleaned up."
fi

echo ""
echo "Deployment complete! Version $VERSION is now live."
echo ""
echo "Active deployments (version $VERSION):"
kubectl get deployments -n $NAMESPACE -l version=$VERSION -o wide
echo ""
echo "All pods (version $VERSION):"
kubectl get pods -n $NAMESPACE -l version=$VERSION
