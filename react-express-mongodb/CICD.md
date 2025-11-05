# CI/CD Pipeline

## Prerequisites

Deploy ArgoCD on your EKS cluster. See `k8s/argocd/README.md` for setup instructions.

## CI Pipeline

Triggers on push to `main` when backend or frontend code changes.

**Steps:**
1. Run unit tests (backend + frontend)
2. Build Docker images
3. Push images to AWS ECR with `latest` tags

## CD Pipeline

Triggers after CI completes successfully.

**Steps:**
1. Triggers ArgoCD sync via CLI
2. ArgoCD pulls manifests from Git
3. ArgoCD deploys to EKS cluster

## GitHub Secrets

Required in repository settings:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `ARGOCD_SERVER`
- `ARGOCD_AUTH_TOKEN`

See `k8s/argocd/README.md` for token generation.
