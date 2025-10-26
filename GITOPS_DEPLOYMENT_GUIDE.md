# GitOps Deployment Guide for QuakeWatch

## Overview

This guide provides comprehensive instructions for deploying QuakeWatch using GitOps principles with ArgoCD. The setup includes automated deployment, monitoring, and alerting configurations.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [ArgoCD Installation](#argocd-installation)
3. [Repository Structure](#repository-structure)
4. [Application Configuration](#application-configuration)
5. [Deployment Process](#deployment-process)
6. [Monitoring Setup](#monitoring-setup)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools
- Kubernetes cluster (minikube, GKE, EKS, etc.)
- kubectl configured
- Git repository access
- ArgoCD CLI (optional but recommended)

### Cluster Requirements
- Kubernetes 1.19+
- 4+ CPU cores
- 8+ GB RAM
- 50+ GB storage

## ArgoCD Installation

### 1. Install ArgoCD

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### 2. Access ArgoCD

```bash
# Port forward ArgoCD server
kubectl port-forward -n argocd svc/argocd-server 8080:80 &

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Access ArgoCD UI
# URL: http://localhost:8080
# Username: admin
# Password: [from command above]
```

### 3. Install ArgoCD CLI (Optional)

```bash
# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Login via CLI
argocd login localhost:8080
```

## Repository Structure

```
quakewatch/
├── argocd/                          # ArgoCD application definitions
│   ├── quakewatch-app.yaml         # QuakeWatch application
│   ├── monitoring-app.yaml         # Monitoring stack
│   └── alerting-app.yaml           # Alerting configuration
├── k8s/                            # Kubernetes manifests
│   ├── 00-config.yaml             # ConfigMaps and Secrets
│   ├── 01-presync-migrate-job.yaml # Database migration
│   ├── deployment.yaml             # QuakeWatch deployment
│   ├── service.yaml                # QuakeWatch service
│   └── monitoring-servicemonitor.yaml # Prometheus ServiceMonitor
├── monitoring/                     # Monitoring configurations
│   ├── prometheus-alerts.yaml     # Alert rules
│   ├── alertmanager-config.yaml   # AlertManager configuration
│   └── grafana-dashboards/        # Grafana dashboards
│       ├── quakewatch-application-dashboard.json
│       ├── cluster-health-dashboard.json
│       └── system-overview-dashboard.json
├── charts/                        # Helm charts (if using Helm)
│   └── quakewatch/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
└── docs/                          # Documentation
    ├── GITOPS_DEPLOYMENT_GUIDE.md
    ├── MONITORING_DOCUMENTATION.md
    └── TROUBLESHOOTING_GUIDE.md
```

## Application Configuration

### 1. QuakeWatch Application

**File**: `argocd/quakewatch-app.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: quakewatch
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/doragayev/quakewatch.git
    targetRevision: HEAD
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: quakewatch
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

**Features**:
- Automated sync with Git repository
- Self-healing capabilities
- Automatic namespace creation
- Prune orphaned resources

### 2. Monitoring Stack Application

**File**: `argocd/monitoring-app.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: monitoring
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://prometheus-community.github.io/helm-charts
    chart: kube-prometheus-stack
    targetRevision: 78.5.0
    helm:
      parameters:
        - name: prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues
          value: "false"
```

**Features**:
- Helm chart deployment
- Prometheus and Grafana stack
- Configurable parameters
- Automated updates

### 3. Alerting Configuration Application

**File**: `argocd/alerting-app.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: alerting
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/doragayev/quakewatch.git
    targetRevision: HEAD
    path: monitoring
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
```

**Features**:
- Custom alert rules
- AlertManager configuration
- Grafana dashboards
- Git-based configuration

## Deployment Process

### 1. Deploy Applications

```bash
# Apply ArgoCD applications
kubectl apply -f argocd/quakewatch-app.yaml
kubectl apply -f argocd/monitoring-app.yaml
kubectl apply -f argocd/alerting-app.yaml

# Check application status
kubectl get applications -n argocd
```

### 2. Monitor Deployment

```bash
# Check application health
argocd app get quakewatch
argocd app get monitoring
argocd app get alerting

# View application logs
argocd app logs quakewatch
argocd app logs monitoring
```

### 3. Access Services

```bash
# Port forward services
kubectl port-forward -n quakewatch svc/quakewatch 8080:80 &
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 &
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090 &
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-alertmanager 9093:9093 &
```

**Access URLs**:
- **ArgoCD**: http://localhost:8080 (admin/[password])
- **QuakeWatch**: http://localhost:8080
- **Grafana**: http://localhost:3000 (admin/prom-operator)
- **Prometheus**: http://localhost:9090
- **AlertManager**: http://localhost:9093

## Monitoring Setup

### 1. Import Grafana Dashboards

1. **Access Grafana**: http://localhost:3000
2. **Login**: admin/prom-operator
3. **Import Dashboards**:
   - Click `+` → `Import`
   - Upload JSON files from `monitoring/grafana-dashboards/`
   - Configure data source (should auto-detect Prometheus)

### 2. Configure Alerting

```bash
# Apply alert rules
kubectl apply -f monitoring/prometheus-alerts.yaml

# Apply AlertManager configuration
kubectl apply -f monitoring/alertmanager-config.yaml

# Check alert status
curl -s 'http://localhost:9090/api/v1/alerts' | jq '.data.alerts[]'
```

### 3. Test Monitoring

```bash
# Test metrics endpoint
curl http://localhost:8080/metrics

# Test alerting
kubectl scale deployment quakewatch --replicas=0 -n quakewatch
# Wait 2 minutes, then scale back
kubectl scale deployment quakewatch --replicas=1 -n quakewatch
```

## GitOps Workflow

### 1. Development Workflow

```bash
# 1. Make changes to application code
git add .
git commit -m "Update QuakeWatch application"
git push origin main

# 2. ArgoCD automatically detects changes
# 3. ArgoCD syncs changes to cluster
# 4. Monitor deployment in ArgoCD UI
```

### 2. Configuration Changes

```bash
# 1. Update Kubernetes manifests
vim k8s/deployment.yaml

# 2. Commit and push changes
git add k8s/deployment.yaml
git commit -m "Update deployment configuration"
git push origin main

# 3. ArgoCD syncs changes automatically
```

### 3. Monitoring Updates

```bash
# 1. Update alert rules
vim monitoring/prometheus-alerts.yaml

# 2. Update dashboards
vim monitoring/grafana-dashboards/quakewatch-application-dashboard.json

# 3. Commit and push changes
git add monitoring/
git commit -m "Update monitoring configuration"
git push origin main

# 4. ArgoCD syncs monitoring changes
```

## ArgoCD Best Practices

### 1. Application Organization

```yaml
# Use projects for organization
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: quakewatch-project
  namespace: argocd
spec:
  description: QuakeWatch project
  sourceRepos:
  - 'https://github.com/doragayev/quakewatch.git'
  - 'https://prometheus-community.github.io/helm-charts'
  destinations:
  - namespace: quakewatch
    server: https://kubernetes.default.svc
  - namespace: monitoring
    server: https://kubernetes.default.svc
```

### 2. Sync Policies

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
  syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
  retry:
    limit: 5
    backoff:
      duration: 5s
      factor: 2
      maxDuration: 3m
```

### 3. Resource Hooks

```yaml
# Pre-sync hook for database migration
apiVersion: batch/v1
kind: Job
metadata:
  name: migrate-db
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      containers:
      - name: migrate
        image: quakewatch:latest
        command: ["python", "migrate.py"]
      restartPolicy: Never
```

## Troubleshooting

### Common Issues

#### 1. Application Not Syncing
**Symptoms**: Application shows "OutOfSync" status
**Solutions**:
```bash
# Check application status
argocd app get quakewatch

# Force sync
argocd app sync quakewatch

# Check logs
argocd app logs quakewatch
```

#### 2. Repository Access Issues
**Symptoms**: "Repository not accessible" error
**Solutions**:
```bash
# Check repository access
argocd repo get https://github.com/doragayev/quakewatch.git

# Add repository credentials
argocd repo add https://github.com/doragayev/quakewatch.git --username [username] --password [token]
```

#### 3. Resource Conflicts
**Symptoms**: "Resource already exists" errors
**Solutions**:
```bash
# Check for existing resources
kubectl get all -n quakewatch

# Delete conflicting resources
kubectl delete [resource] [name] -n quakewatch

# Re-sync application
argocd app sync quakewatch
```

### Debugging Commands

```bash
# Check application health
argocd app health quakewatch

# View application resources
argocd app resources quakewatch

# Check application events
kubectl get events -n quakewatch

# View application logs
kubectl logs -n quakewatch deployment/quakewatch
```

## Security Considerations

### 1. RBAC Configuration

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: argocd-application-controller
rules:
- apiGroups: [""]
  resources: ["secrets", "configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "update", "patch"]
```

### 2. Repository Security

```yaml
# Use SSH keys for repository access
apiVersion: v1
kind: Secret
metadata:
  name: repo-ssh-key
  namespace: argocd
type: Opaque
stringData:
  sshPrivateKey: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    [private key content]
    -----END OPENSSH PRIVATE KEY-----
```

### 3. Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: argocd-netpol
  namespace: argocd
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: argocd-server
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: argocd
```

## Maintenance

### 1. Regular Tasks

#### Daily
- Check application health
- Review sync status
- Monitor resource usage

#### Weekly
- Review application logs
- Check for failed syncs
- Update documentation

#### Monthly
- Review and update configurations
- Check for security updates
- Backup configurations

### 2. Backup Procedures

```bash
# Backup ArgoCD applications
kubectl get applications -n argocd -o yaml > argocd-applications-backup.yaml

# Backup application configurations
kubectl get all -n quakewatch -o yaml > quakewatch-resources-backup.yaml
kubectl get all -n monitoring -o yaml > monitoring-resources-backup.yaml
```

### 3. Disaster Recovery

```bash
# Restore ArgoCD applications
kubectl apply -f argocd-applications-backup.yaml

# Restore application resources
kubectl apply -f quakewatch-resources-backup.yaml
kubectl apply -f monitoring-resources-backup.yaml

# Re-sync applications
argocd app sync quakewatch
argocd app sync monitoring
argocd app sync alerting
```

## Conclusion

This GitOps deployment guide provides comprehensive instructions for deploying and managing QuakeWatch using ArgoCD. The setup ensures automated deployment, monitoring, and alerting with proper GitOps principles.

For additional support:
- Check ArgoCD documentation
- Review application logs
- Use ArgoCD CLI for debugging
- Refer to troubleshooting guide
