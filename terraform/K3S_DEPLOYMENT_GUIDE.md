# k3s Cluster Deployment Guide for QuakeWatch

## Overview

This guide provides comprehensive instructions for deploying a k3s cluster on AWS EC2 instances and deploying the QuakeWatch application with full automation.

## 🎯 **What This Guide Covers**

### ✅ **k3s Installation**
- Automated k3s installation on EC2 instances
- Master and worker node configuration
- Cloud provider integration
- High availability setup

### ✅ **QuakeWatch Deployment**
- Automated QuakeWatch application deployment
- Kubernetes manifests and services
- Ingress controller setup
- External access configuration

### ✅ **Cluster Validation**
- Comprehensive validation scripts
- Health checks and connectivity tests
- Access verification
- Troubleshooting guides

## 🏗️ **Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                           Internet                              │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                    Application Load Balancer                   │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                   k3s Cluster                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │ k3s Master  │  │ k3s Worker  │  │ k3s Worker  │            │
│  │             │  │             │  │             │            │
│  │ QuakeWatch  │  │ QuakeWatch  │  │ QuakeWatch  │            │
│  │   Pods      │  │   Pods      │  │   Pods      │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 **Quick Start**

### **Step 1: Deploy Infrastructure**
```bash
# Navigate to terraform directory
cd terraform

# Configure variables
cp terraform.tfvars.free-tier terraform.tfvars
# Edit terraform.tfvars with your details

# Deploy infrastructure
terraform init
terraform plan
terraform apply
```

### **Step 2: Access Your Cluster**
```bash
# Get connection information
terraform output

# SSH to bastion host
ssh -i ~/.ssh/quakewatch-key ubuntu@$(terraform output -raw bastion_public_ip)

# From bastion, SSH to k3s master
ssh -i ~/.ssh/quakewatch-key ubuntu@<master-private-ip>
```

### **Step 3: Verify Deployment**
```bash
# Run validation script
./validate-cluster.sh

# Check QuakeWatch status
kubectl get pods -n quakewatch
kubectl get svc -n quakewatch
```

## 📋 **Deployment Process**

### **1. Infrastructure Provisioning**
- **VPC**: Multi-AZ setup with public/private subnets
- **EC2 Instances**: t2.micro (free tier) or t3.medium/large
- **Security Groups**: Proper network segmentation
- **IAM Roles**: Minimal required permissions
- **Load Balancer**: ALB for external access

### **2. k3s Installation**
- **Automated Setup**: User data scripts install k3s
- **Master Node**: Single or HA master configuration
- **Worker Nodes**: Scalable worker nodes
- **Cloud Integration**: AWS cloud provider
- **Networking**: Flannel CNI with VXLAN

### **3. QuakeWatch Deployment**
- **Namespace**: Dedicated quakewatch namespace
- **Deployment**: QuakeWatch application pods
- **Services**: ClusterIP and NodePort services
- **Ingress**: NGINX ingress controller
- **External Access**: ALB and NodePort access

## 🔧 **Configuration Files**

### **Terraform Files**
- `main.tf` - Provider configuration
- `vpc.tf` - VPC and networking
- `security-groups.tf` - Security groups
- `iam.tf` - IAM roles and policies
- `ec2.tf` - EC2 instances and ALB
- `provisioners.tf` - k3s installation automation
- `variables.tf` - Input variables
- `outputs.tf` - Output values

### **User Data Scripts**
- `scripts/k3s-master-userdata.sh` - Master node setup
- `scripts/k3s-worker-userdata.sh` - Worker node setup
- `scripts/bastion-userdata.sh` - Bastion host setup

### **Deployment Scripts**
- `scripts/deploy-quakewatch.sh` - QuakeWatch deployment
- `scripts/validate-cluster.sh` - Cluster validation
- `scripts/validate-cluster.sh` - Health checks

## 🎯 **k3s Installation Process**

### **Master Node Setup**
```bash
# 1. Install k3s server
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - \
    --token=${K3S_TOKEN} \
    --cluster-init \
    --disable=traefik \
    --disable=servicelb \
    --disable=local-storage \
    --disable=metrics-server \
    --write-kubeconfig-mode=644

# 2. Configure cloud provider
--kubelet-arg="cloud-provider=external" \
--kubelet-arg="provider-id=aws:///..."

# 3. Deploy QuakeWatch
kubectl apply -f quakewatch/k8s/ -n quakewatch
```

### **Worker Node Setup**
```bash
# 1. Install k3s agent
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent" sh -s - \
    --token=${K3S_TOKEN} \
    --server=https://${K3S_SERVER}:6443

# 2. Configure cloud provider
--kubelet-arg="cloud-provider=external" \
--kubelet-arg="provider-id=aws:///..."
```

## 🚀 **QuakeWatch Deployment**

### **Application Components**
- **Deployment**: QuakeWatch application pods
- **Service**: ClusterIP service for internal access
- **NodePort**: External access via NodePort
- **Ingress**: ALB access via ingress controller

### **Deployment Process**
```bash
# 1. Create namespace
kubectl create namespace quakewatch

# 2. Deploy application
kubectl apply -f k8s/deployment.yaml -n quakewatch
kubectl apply -f k8s/service.yaml -n quakewatch

# 3. Install ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# 4. Create ingress
kubectl apply -f k8s/ingress.yaml -n quakewatch
```

## ✅ **Cluster Validation**

### **Validation Scripts**
- **Comprehensive Checks**: Nodes, pods, services, ingress
- **Health Monitoring**: Application health and connectivity
- **Access Testing**: Internal and external access verification
- **Resource Monitoring**: CPU, memory, and storage usage

### **Validation Commands**
```bash
# Check cluster status
kubectl get nodes
kubectl get pods -A
kubectl get svc -A

# Check QuakeWatch
kubectl get pods -n quakewatch
kubectl get svc -n quakewatch
kubectl get ingress -n quakewatch

# Test connectivity
kubectl port-forward -n quakewatch svc/quakewatch 8080:80
curl http://localhost:8080
```

## 🌐 **External Access**

### **Access Methods**
1. **NodePort**: `http://<node-ip>:30000`
2. **ALB**: `http://<alb-dns-name>`
3. **Port-Forward**: `kubectl port-forward -n quakewatch svc/quakewatch 8080:80`

### **Access Configuration**
- **Security Groups**: Allow HTTP/HTTPS traffic
- **ALB**: Application Load Balancer for external access
- **Ingress**: NGINX ingress controller
- **SSL/TLS**: Optional SSL certificate configuration

## 🔍 **Troubleshooting**

### **Common Issues**

#### **1. k3s Not Starting**
```bash
# Check k3s service
sudo systemctl status k3s
sudo journalctl -u k3s -f

# Check k3s configuration
sudo cat /etc/rancher/k3s/k3s.yaml
```

#### **2. QuakeWatch Not Accessible**
```bash
# Check pods
kubectl get pods -n quakewatch
kubectl describe pod -n quakewatch -l app=quakewatch

# Check services
kubectl get svc -n quakewatch
kubectl describe svc -n quakewatch quakewatch

# Check logs
kubectl logs -n quakewatch -l app=quakewatch
```

#### **3. Network Issues**
```bash
# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>

# Check ALB
kubectl get ingress -n quakewatch
kubectl describe ingress -n quakewatch quakewatch-ingress
```

### **Debug Commands**
```bash
# Cluster info
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -A -o wide

# QuakeWatch specific
kubectl get all -n quakewatch
kubectl logs -n quakewatch -l app=quakewatch --tail=50
kubectl describe pod -n quakewatch -l app=quakewatch
```

## 📊 **Monitoring and Logging**

### **Cluster Monitoring**
- **Node Status**: CPU, memory, disk usage
- **Pod Health**: Running, ready, restart counts
- **Service Status**: Endpoints and connectivity
- **Ingress Status**: ALB and ingress controller

### **Application Monitoring**
- **QuakeWatch Logs**: Application logs and errors
- **Performance**: Response times and throughput
- **Health Checks**: Liveness and readiness probes
- **Metrics**: Custom application metrics

### **Logging Commands**
```bash
# System logs
sudo journalctl -u k3s -f
sudo journalctl -u k3s-agent -f

# Application logs
kubectl logs -n quakewatch -l app=quakewatch -f
kubectl logs -n quakewatch -l app=quakewatch --tail=100
```

## 🔧 **Maintenance**

### **Regular Tasks**
- **Update k3s**: Upgrade k3s version
- **Update QuakeWatch**: Deploy new application versions
- **Monitor Resources**: Check CPU, memory, storage
- **Review Logs**: Check for errors and issues

### **Scaling Operations**
- **Add Workers**: Scale worker nodes
- **Scale Application**: Increase QuakeWatch replicas
- **Update Configuration**: Modify application settings
- **Backup Data**: Backup k3s data and configurations

### **Update Commands**
```bash
# Update k3s
curl -sfL https://get.k3s.io | sh -s - --upgrade

# Update QuakeWatch
kubectl set image deployment/quakewatch quakewatch=doragayev/quakewatch:latest -n quakewatch

# Scale application
kubectl scale deployment quakewatch --replicas=3 -n quakewatch
```

## 🎯 **Best Practices**

### **Security**
- **Network Segmentation**: Private subnets for k3s nodes
- **Security Groups**: Minimal required access
- **IAM Roles**: Least privilege permissions
- **Encryption**: Encrypted EBS volumes

### **Performance**
- **Right-sizing**: Appropriate instance types
- **Resource Limits**: CPU and memory limits
- **Health Checks**: Proper liveness and readiness probes
- **Monitoring**: Comprehensive monitoring setup

### **Reliability**
- **High Availability**: Multi-AZ deployment
- **Backup Strategy**: Regular backups
- **Disaster Recovery**: Recovery procedures
- **Testing**: Regular validation and testing

## 📚 **Additional Resources**

### **Documentation**
- [k3s Documentation](https://k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)

### **Tools**
- **kubectl**: Kubernetes command-line tool
- **helm**: Kubernetes package manager
- **terraform**: Infrastructure as code
- **aws-cli**: AWS command-line interface

## 🎉 **Conclusion**

This guide provides a complete solution for deploying QuakeWatch on a k3s cluster with full automation. The setup includes:

- ✅ **Automated Infrastructure**: Terraform for AWS resources
- ✅ **Automated k3s Installation**: User data scripts
- ✅ **Automated QuakeWatch Deployment**: Kubernetes manifests
- ✅ **Comprehensive Validation**: Health checks and testing
- ✅ **External Access**: ALB and NodePort access
- ✅ **Monitoring**: Logging and health monitoring

The deployment is production-ready with proper security, monitoring, and scalability features.
