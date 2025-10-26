#!/bin/bash
# QuakeWatch k3s Cluster Validation Script
# This script validates the k3s cluster and QuakeWatch deployment

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if kubectl is configured
check_kubectl() {
    if command_exists kubectl; then
        if kubectl cluster-info >/dev/null 2>&1; then
            print_status "OK" "kubectl is configured and cluster is accessible"
            return 0
        else
            print_status "ERROR" "kubectl is not configured or cluster is not accessible"
            return 1
        fi
    else
        print_status "ERROR" "kubectl is not installed"
        return 1
    fi
}

# Function to check cluster nodes
check_nodes() {
    print_status "INFO" "Checking cluster nodes..."
    
    local node_count=$(kubectl get nodes --no-headers | wc -l)
    local ready_nodes=$(kubectl get nodes --no-headers | grep -c "Ready" || echo "0")
    
    if [ "$node_count" -gt 0 ]; then
        print_status "OK" "Found $node_count nodes, $ready_nodes ready"
        kubectl get nodes -o wide
    else
        print_status "ERROR" "No nodes found in cluster"
        return 1
    fi
}

# Function to check QuakeWatch namespace
check_namespace() {
    print_status "INFO" "Checking QuakeWatch namespace..."
    
    if kubectl get namespace quakewatch >/dev/null 2>&1; then
        print_status "OK" "QuakeWatch namespace exists"
    else
        print_status "WARN" "QuakeWatch namespace not found, creating it..."
        kubectl create namespace quakewatch
    fi
}

# Function to check QuakeWatch deployment
check_quakewatch_deployment() {
    print_status "INFO" "Checking QuakeWatch deployment..."
    
    if kubectl get deployment quakewatch -n quakewatch >/dev/null 2>&1; then
        local replicas=$(kubectl get deployment quakewatch -n quakewatch -o jsonpath='{.spec.replicas}')
        local ready_replicas=$(kubectl get deployment quakewatch -n quakewatch -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        
        if [ "$ready_replicas" -eq "$replicas" ]; then
            print_status "OK" "QuakeWatch deployment is ready ($ready_replicas/$replicas replicas)"
        else
            print_status "WARN" "QuakeWatch deployment is not ready ($ready_replicas/$replicas replicas)"
        fi
        
        kubectl get pods -n quakewatch -o wide
    else
        print_status "ERROR" "QuakeWatch deployment not found"
        return 1
    fi
}

# Function to check QuakeWatch services
check_quakewatch_services() {
    print_status "INFO" "Checking QuakeWatch services..."
    
    local service_count=$(kubectl get svc -n quakewatch --no-headers | wc -l)
    
    if [ "$service_count" -gt 0 ]; then
        print_status "OK" "Found $service_count QuakeWatch services"
        kubectl get svc -n quakewatch
    else
        print_status "WARN" "No QuakeWatch services found"
    fi
}

# Function to check QuakeWatch ingress
check_quakewatch_ingress() {
    print_status "INFO" "Checking QuakeWatch ingress..."
    
    if kubectl get ingress quakewatch-ingress -n quakewatch >/dev/null 2>&1; then
        print_status "OK" "QuakeWatch ingress exists"
        kubectl get ingress -n quakewatch
    else
        print_status "WARN" "QuakeWatch ingress not found"
    fi
}

# Function to check QuakeWatch logs
check_quakewatch_logs() {
    print_status "INFO" "Checking QuakeWatch logs..."
    
    local pod_name=$(kubectl get pods -n quakewatch -l app=quakewatch -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -n "$pod_name" ]; then
        print_status "OK" "Found QuakeWatch pod: $pod_name"
        echo "Last 10 lines of QuakeWatch logs:"
        kubectl logs -n quakewatch "$pod_name" --tail=10
    else
        print_status "ERROR" "No QuakeWatch pods found"
        return 1
    fi
}

# Function to check external access
check_external_access() {
    print_status "INFO" "Checking external access..."
    
    # Check NodePort service
    local nodeport=$(kubectl get svc quakewatch-nodeport -n quakewatch -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "")
    
    if [ -n "$nodeport" ]; then
        print_status "OK" "QuakeWatch NodePort service is available on port $nodeport"
        echo "Access via: http://<node-ip>:$nodeport"
    else
        print_status "WARN" "QuakeWatch NodePort service not found"
    fi
    
    # Check ALB
    local alb_dns=$(kubectl get ingress quakewatch-ingress -n quakewatch -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [ -n "$alb_dns" ]; then
        print_status "OK" "QuakeWatch ALB is available at $alb_dns"
        echo "Access via: http://$alb_dns"
    else
        print_status "WARN" "QuakeWatch ALB not found"
    fi
}

# Function to test QuakeWatch connectivity
test_quakewatch_connectivity() {
    print_status "INFO" "Testing QuakeWatch connectivity..."
    
    local pod_name=$(kubectl get pods -n quakewatch -l app=quakewatch -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    
    if [ -n "$pod_name" ]; then
        # Test internal connectivity
        if kubectl exec -n quakewatch "$pod_name" -- curl -s http://localhost:5000 >/dev/null 2>&1; then
            print_status "OK" "QuakeWatch is responding internally"
        else
            print_status "WARN" "QuakeWatch is not responding internally"
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
    else
        print_status "ERROR" "Cannot test connectivity - no QuakeWatch pods found"
    fi
}

# Function to check cluster resources
check_cluster_resources() {
    print_status "INFO" "Checking cluster resources..."
    
    echo "Node resources:"
    kubectl top nodes 2>/dev/null || echo "Metrics server not available"
    
    echo "Pod resources:"
    kubectl top pods -n quakewatch 2>/dev/null || echo "Metrics server not available"
    
    echo "Cluster events:"
    kubectl get events --sort-by=.metadata.creationTimestamp | tail -10
}

# Function to check cluster health
check_cluster_health() {
    print_status "INFO" "Checking cluster health..."
    
    # Check cluster info
    kubectl cluster-info
    
    # Check system pods
    echo "System pods:"
    kubectl get pods -n kube-system
    
    # Check ingress controller
    if kubectl get pods -n ingress-nginx >/dev/null 2>&1; then
        print_status "OK" "NGINX Ingress Controller is running"
        kubectl get pods -n ingress-nginx
    else
        print_status "WARN" "NGINX Ingress Controller not found"
    fi
}

# Main validation function
main() {
    echo "=== QuakeWatch k3s Cluster Validation ==="
    echo "Date: $(date)"
    echo "Cluster: $(kubectl config current-context 2>/dev/null || echo 'No context')"
    echo ""
    
    local exit_code=0
    
    # Check prerequisites
    if ! check_kubectl; then
        print_status "ERROR" "Cannot proceed without kubectl access"
        exit 1
    fi
    
    # Run all checks
    check_nodes || exit_code=1
    echo ""
    
    check_namespace || exit_code=1
    echo ""
    
    check_quakewatch_deployment || exit_code=1
    echo ""
    
    check_quakewatch_services || exit_code=1
    echo ""
    
    check_quakewatch_ingress || exit_code=1
    echo ""
    
    check_quakewatch_logs || exit_code=1
    echo ""
    
    check_external_access || exit_code=1
    echo ""
    
    test_quakewatch_connectivity || exit_code=1
    echo ""
    
    check_cluster_resources || exit_code=1
    echo ""
    
    check_cluster_health || exit_code=1
    echo ""
    
    # Summary
    if [ $exit_code -eq 0 ]; then
        print_status "OK" "All validations passed! QuakeWatch k3s cluster is healthy."
    else
        print_status "ERROR" "Some validations failed. Please check the output above."
    fi
    
    echo ""
    echo "=== Validation Summary ==="
    echo "Cluster: $(kubectl config current-context)"
    echo "Nodes: $(kubectl get nodes --no-headers | wc -l)"
    echo "QuakeWatch Pods: $(kubectl get pods -n quakewatch --no-headers | wc -l)"
    echo "QuakeWatch Services: $(kubectl get svc -n quakewatch --no-headers | wc -l)"
    echo "Exit Code: $exit_code"
    
    exit $exit_code
}

# Run main function
main "$@"
