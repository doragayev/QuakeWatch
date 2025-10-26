#!/bin/bash
# QuakeWatch Deployment Script for k3s Cluster
# This script automates the deployment of QuakeWatch to the k3s cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK")
            echo -e "${GREEN}✓${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}✗${NC} $message"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ${NC} $message"
            ;;
    esac
}

# Function to check if kubectl is configured
check_kubectl() {
    if kubectl cluster-info >/dev/null 2>&1; then
        print_status "OK" "kubectl is configured and cluster is accessible"
        return 0
    else
        print_status "ERROR" "kubectl is not configured or cluster is not accessible"
        return 1
    fi
}

# Function to create QuakeWatch namespace
create_namespace() {
    print_status "INFO" "Creating QuakeWatch namespace..."
    
    if kubectl get namespace quakewatch >/dev/null 2>&1; then
        print_status "OK" "QuakeWatch namespace already exists"
    else
        kubectl create namespace quakewatch
        print_status "OK" "QuakeWatch namespace created"
    fi
}

# Function to deploy QuakeWatch application
deploy_quakewatch() {
    print_status "INFO" "Deploying QuakeWatch application..."
    
    # Create QuakeWatch deployment
    cat << 'EOF' | kubectl apply -f -
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
EOF

    print_status "OK" "QuakeWatch deployment created"
}

# Function to create QuakeWatch service
create_service() {
    print_status "INFO" "Creating QuakeWatch service..."
    
    cat << 'EOF' | kubectl apply -f -
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
EOF

    print_status "OK" "QuakeWatch service created"
}

# Function to create NodePort service for external access
create_nodeport_service() {
    print_status "INFO" "Creating QuakeWatch NodePort service..."
    
    cat << 'EOF' | kubectl apply -f -
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

    print_status "OK" "QuakeWatch NodePort service created"
}

# Function to create QuakeWatch ingress
create_ingress() {
    print_status "INFO" "Creating QuakeWatch ingress..."
    
    cat << 'EOF' | kubectl apply -f -
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

    print_status "OK" "QuakeWatch ingress created"
}

# Function to install NGINX Ingress Controller
install_ingress_controller() {
    print_status "INFO" "Installing NGINX Ingress Controller..."
    
    if kubectl get pods -n ingress-nginx >/dev/null 2>&1; then
        print_status "OK" "NGINX Ingress Controller already installed"
    else
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
        
        print_status "INFO" "Waiting for ingress controller to be ready..."
        kubectl wait --namespace ingress-nginx \
          --for=condition=ready pod \
          --selector=app.kubernetes.io/component=controller \
          --timeout=300s
        
        print_status "OK" "NGINX Ingress Controller installed and ready"
    fi
}

# Function to wait for QuakeWatch to be ready
wait_for_quakewatch() {
    print_status "INFO" "Waiting for QuakeWatch to be ready..."
    
    kubectl wait --for=condition=available --timeout=300s deployment/quakewatch -n quakewatch
    
    print_status "OK" "QuakeWatch is ready"
}

# Function to verify deployment
verify_deployment() {
    print_status "INFO" "Verifying QuakeWatch deployment..."
    
    echo "QuakeWatch Pods:"
    kubectl get pods -n quakewatch -o wide
    
    echo "QuakeWatch Services:"
    kubectl get svc -n quakewatch
    
    echo "QuakeWatch Ingress:"
    kubectl get ingress -n quakewatch
    
    echo "QuakeWatch Logs (last 10 lines):"
    kubectl logs -n quakewatch -l app=quakewatch --tail=10
}

# Function to test connectivity
test_connectivity() {
    print_status "INFO" "Testing QuakeWatch connectivity..."
    
    # Test internal connectivity
    local pod_name=$(kubectl get pods -n quakewatch -l app=quakewatch -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -n "$pod_name" ]; then
        if kubectl exec -n quakewatch "$pod_name" -- curl -s http://localhost:5000 >/dev/null 2>&1; then
            print_status "OK" "QuakeWatch is responding internally"
        else
            print_status "WARN" "QuakeWatch is not responding internally"
        fi
    else
        print_status "ERROR" "No QuakeWatch pods found"
        return 1
    fi
    
    # Test external connectivity via port-forward
    print_status "INFO" "Testing external connectivity via port-forward..."
    kubectl port-forward -n quakewatch svc/quakewatch 8080:80 &
    local pf_pid=$!
    sleep 5
    
    if curl -s http://localhost:8080 >/dev/null 2>&1; then
        print_status "OK" "QuakeWatch is accessible via port-forward"
    else
        print_status "WARN" "QuakeWatch is not accessible via port-forward"
    fi
    
    kill $pf_pid 2>/dev/null || true
}

# Function to show access information
show_access_info() {
    print_status "INFO" "QuakeWatch Access Information:"
    
    echo "1. NodePort Access:"
    echo "   - Port: 30000"
    echo "   - Access via: http://<node-ip>:30000"
    
    echo "2. Port-Forward Access:"
    echo "   - Command: kubectl port-forward -n quakewatch svc/quakewatch 8080:80"
    echo "   - Access via: http://localhost:8080"
    
    echo "3. Ingress Access:"
    echo "   - Host: quakewatch.local"
    echo "   - Access via: http://quakewatch.local (after DNS setup)"
    
    echo "4. ALB Access:"
    echo "   - Check ingress status for ALB DNS name"
    kubectl get ingress quakewatch-ingress -n quakewatch -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "   - ALB DNS not available yet"
}

# Main deployment function
main() {
    echo "=== QuakeWatch k3s Deployment ==="
    echo "Date: $(date)"
    echo "Cluster: $(kubectl config current-context 2>/dev/null || echo 'No context')"
    echo ""
    
    # Check prerequisites
    if ! check_kubectl; then
        print_status "ERROR" "Cannot proceed without kubectl access"
        exit 1
    fi
    
    # Deploy QuakeWatch
    create_namespace
    echo ""
    
    deploy_quakewatch
    echo ""
    
    create_service
    echo ""
    
    create_nodeport_service
    echo ""
    
    install_ingress_controller
    echo ""
    
    create_ingress
    echo ""
    
    wait_for_quakewatch
    echo ""
    
    verify_deployment
    echo ""
    
    test_connectivity
    echo ""
    
    show_access_info
    echo ""
    
    print_status "OK" "QuakeWatch deployment completed successfully!"
}

# Run main function
main "$@"
