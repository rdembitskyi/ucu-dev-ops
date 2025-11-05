#!/bin/bash
# Install ArgoCD to the cluster

echo "Creating ArgoCD namespace..."
kubectl apply -f namespace.yaml

echo "Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo "ArgoCD installed successfully!"

echo ""
echo "Creating LoadBalancer service..."
kubectl apply -f service-lb.yaml

echo ""
echo "Waiting for LoadBalancer to be ready..."
kubectl wait --for=jsonpath='{.status.loadBalancer.ingress}' service/argocd-server-lb -n argocd --timeout=30s



