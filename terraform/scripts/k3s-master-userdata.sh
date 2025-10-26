#!/bin/bash
# k3s Master Node User Data Script with QuakeWatch Deployment

set -e

# Variables
PROJECT_NAME="${project_name}"
ENVIRONMENT="${environment}"
K3S_TOKEN="${k3s_token}"
NODE_INDEX="${node_index}"
IS_FIRST_MASTER="${is_first_master}"

# Logging
exec > >(tee /var/log/k3s-master-setup.log)
exec 2>&1

echo "Starting k3s master setup at $(date)"

# Update system
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y curl wget git vim htop jq unzip

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install k3s
echo "Installing k3s..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - \
    --token=${K3S_TOKEN} \
    --cluster-init \
    --disable=traefik \
    --disable=servicelb \
    --disable=local-storage \
    --disable=metrics-server \
    --write-kubeconfig-mode=644 \
    --kubelet-arg="cloud-provider=external" \
    --kubelet-arg="provider-id=aws:///$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"

# Wait for k3s to start
echo "Waiting for k3s to start..."
sleep 60

# Verify k3s is running
systemctl status k3s --no-pager

# Create project directory
mkdir -p /opt/${PROJECT_NAME}
cd /opt/${PROJECT_NAME}

# Clone QuakeWatch repository
echo "Cloning QuakeWatch repository..."
git clone https://github.com/doragayev/quakewatch.git || {
    echo "Failed to clone repository, creating local files..."
    mkdir -p quakewatch/k8s
}

# Create QuakeWatch namespace
kubectl create namespace quakewatch --dry-run=client -o yaml | kubectl apply -f -

# Deploy QuakeWatch application
echo "Deploying QuakeWatch application..."
if [ -d "quakewatch/k8s" ]; then
    kubectl apply -f quakewatch/k8s/ -n quakewatch
else
    echo "QuakeWatch manifests not found, creating basic deployment..."
    # Create basic QuakeWatch deployment
    cat > /tmp/quakewatch-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: quakewatch
  namespace: quakewatch
  labels:
    app: quakewatch
spec:
  replicas: 1
  selector:
    matchLabels:
      app: quakewatch
  template:
    metadata:
      labels:
        app: quakewatch
    spec:
      containers:
      - name: quakewatch
        image: doragayev/quakewatch:latest
        ports:
        - containerPort: 5000
        env:
        - name: FLASK_ENV
          value: "production"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: quakewatch
  namespace: quakewatch
  labels:
    app: quakewatch
spec:
  type: ClusterIP
  selector:
    app: quakewatch
  ports:
  - name: http
    port: 80
    targetPort: 5000
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: quakewatch-ingress
  namespace: quakewatch
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: quakewatch.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: quakewatch
            port:
              number: 80
EOF
    
    kubectl apply -f /tmp/quakewatch-deployment.yaml
fi

# Install NGINX Ingress Controller
echo "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Wait for ingress controller to be ready
echo "Waiting for ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

# Create NodePort service for external access
cat > /tmp/quakewatch-nodeport.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: quakewatch-nodeport
  namespace: quakewatch
  labels:
    app: quakewatch
spec:
  type: NodePort
  selector:
    app: quakewatch
  ports:
  - name: http
    port: 80
    targetPort: 5000
    nodePort: 30000
EOF

kubectl apply -f /tmp/quakewatch-nodeport.yaml

# Wait for QuakeWatch to be ready
echo "Waiting for QuakeWatch to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/quakewatch -n quakewatch

# Verify deployment
echo "Verifying QuakeWatch deployment..."
kubectl get pods -n quakewatch
kubectl get svc -n quakewatch
kubectl get ingress -n quakewatch

# Create useful aliases and scripts
cat >> /home/ubuntu/.bashrc << EOF

# QuakeWatch k3s aliases
alias k='kubectl'
alias k3s-status='systemctl status k3s'
alias k3s-logs='journalctl -u k3s -f'
alias qw-pods='kubectl get pods -n quakewatch'
alias qw-svc='kubectl get svc -n quakewatch'
alias qw-logs='kubectl logs -n quakewatch -l app=quakewatch'
alias qw-describe='kubectl describe pod -n quakewatch -l app=quakewatch'

# Project aliases
alias cd-project='cd /opt/${PROJECT_NAME}'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

EOF

# Create validation script
cat > /opt/${PROJECT_NAME}/validate-cluster.sh << 'EOF'
#!/bin/bash
echo "=== QuakeWatch k3s Cluster Validation ==="
echo "Date: $(date)"
echo ""

echo "1. k3s Service Status:"
systemctl status k3s --no-pager -l
echo ""

echo "2. Node Status:"
kubectl get nodes -o wide
echo ""

echo "3. QuakeWatch Pods:"
kubectl get pods -n quakewatch -o wide
echo ""

echo "4. QuakeWatch Services:"
kubectl get svc -n quakewatch
echo ""

echo "5. QuakeWatch Ingress:"
kubectl get ingress -n quakewatch
echo ""

echo "6. QuakeWatch Logs (last 10 lines):"
kubectl logs -n quakewatch -l app=quakewatch --tail=10
echo ""

echo "7. Cluster Info:"
kubectl cluster-info
echo ""

echo "8. External Access:"
echo "QuakeWatch is accessible on NodePort 30000"
echo "Access via: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):30000"
echo ""

echo "Validation completed!"
EOF

chmod +x /opt/${PROJECT_NAME}/validate-cluster.sh

# Run validation
echo "Running cluster validation..."
/opt/${PROJECT_NAME}/validate-cluster.sh

echo "k3s master setup and QuakeWatch deployment completed successfully!"
