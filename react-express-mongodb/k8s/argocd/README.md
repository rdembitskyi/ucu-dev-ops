# ArgoCD Setup

## Quick Install

```bash
# Install ArgoCD
./install.sh

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo

# Get LoadBalancer URL
kubectl get svc argocd-server-lb -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Access UI at the LoadBalancer URL
# Username: admin
# Password: <from above>

# Generate token for GitHub Actions
argocd login $ARGOCD_SERVER --username admin --password <PASSWORD> --grpc-web
argocd account generate-token --account admin
```