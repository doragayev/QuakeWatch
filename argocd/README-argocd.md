# QuakeWatch — GitOps with ArgoCD

This guide explains how we manage QuakeWatch deployments via ArgoCD (GitOps).

## Prerequisites
- Kubernetes cluster (k3s)
- `kubectl` configured to the cluster
- ArgoCD installed in namespace `argocd`
- (Optional) `argocd` CLI

---

## 1) Access ArgoCD UI / CLI
Port-forward (local dev):
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
UI: https://localhost:8080
 (self-signed cert → “Proceed”)

CLI login:
argocd login localhost:8080 --username admin --insecure
# password from:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

Create/Apply the ArgoCD Application

Apply the Application CR:
```bash
kubectl apply -f argocd/apps/quakewatch-app.yaml -n argocd
```

Validate:
```bash
kubectl get applications -n argocd
argocd app get quakewatch
```
What it does

Watches repo: https://github.com/doragayev/QuakeWatch.git

Path: k8s/

Auto-sync enabled (prune, selfHeal, CreateNamespace)

Developer Workflow (GitOps)

Edit Kubernetes manifests in QuakeWatch/k8s/

Examples:

k8s/deployment.yaml

k8s/service.yaml

k8s/00-config.yaml (ConfigMap, wave -1)

k8s/01-presync-migrate-job.yaml (PreSync hook)

Commit & push:
```bash
git add k8s/
git commit -m "Update k8s manifests"
git push
```

ArgoCD detects the change and syncs automatically.

Track status:

UI → Application quakewatch

CLI:
```bash
argocd app get quakewatch
argocd app history quakewatch
kubectl -n quakewatch get all
```
Manual Sync (if auto-sync is disabled)
```bash
argocd app sync quakewatch
argocd app wait quakewatch --health --sync
```

Rollbacks

ArgoCD tracks revisions:
```bash
argocd app history quakewatch
# choose an ID from history:
argocd app rollback quakewatch <ID>
```

Health & Troubleshooting

OutOfSync → check Git path/branch.

ImagePullBackOff → ensure image/tag exists (registry access).

Hook failed → check Job logs:
```bash
kubectl -n quakewatch logs job/quakewatch-presync-migrate
```

Inspect application:
```bash
argocd app get quakewatch
kubectl -n quakewatch get events
```

Security Notes

Local dev uses self-signed TLS (--insecure). In production, terminate TLS with real certs.

For private repos, add repo credentials:
```bash
argocd repo add https://github.com/<user>/<repo>.git \
  --username <user> --password <token> --insecure-skip-server-verification
```

(Optional) AppProject policy

To restrict allowed repos/namespaces/clusters, create an AppProject and reference it in the Application.


### (אופציונלי) `argocd/projects/quakewatch-project.yaml`
אם תרצה לגדר הרשאות (מאוד מומלץ בפרודקשן):
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: quakewatch
  namespace: argocd
spec:
  description: Project for QuakeWatch GitOps
  sourceRepos:
    - 'https://github.com/doragayev/*'
  destinations:
    - namespace: 'quakewatch'
      server: https://kubernetes.default.svc
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
```

ואז בקובץ האפליקציה תעדכן:
```yaml
spec:
  project: quakewatch
  # ...
```
