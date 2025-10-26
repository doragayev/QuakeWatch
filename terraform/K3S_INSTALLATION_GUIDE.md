# k3s Installation Guide for QuakeWatch Cluster

## Overview

This guide provides detailed instructions for installing and configuring k3s on AWS EC2 instances for the QuakeWatch application. The installation process is fully automated using Terraform provisioners and user data scripts.

## 🎯 **k3s Installation Process**

### **Installation Overview**
1. **Infrastructure Provisioning**: AWS EC2 instances with proper networking
2. **k3s Master Installation**: Control plane setup with cloud provider integration
3. **k3s Worker Installation**: Worker nodes joining the cluster
4. **QuakeWatch Deployment**: Application deployment to the cluster
5. **Validation**: Comprehensive health checks and connectivity tests

## 🏗️ **k3s Architecture**

### **Cluster Components**
```
┌─────────────────────────────────────────────────────────────────┐
│                        k3s Cluster                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │ k3s Master  │  │ k3s Worker  │  │ k3s Worker  │            │
│  │             │  │             │  │             │            │
│  │ - API Server│  │ - kubelet   │  │ - kubelet   │            │
│  │ - etcd      │  │ - kube-proxy│  │ - kube-proxy│            │
│  │ - Scheduler │  │ - Flannel   │  │ - Flannel   │            │
│  │ - Controller│  │             │  │             │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

### **k3s Features**
- **Lightweight**: Single binary installation
- **Production Ready**: High availability and security
- **Cloud Native**: AWS cloud provider integration
- **CNI**: Flannel with VXLAN networking
- **Storage**: Local storage and cloud storage integration

## 🚀 **Installation Steps**

### **Step 1: Master Node Installation**

#### **User Data Script Configuration**
```bash
#!/bin/bash
# k3s Master Node User Data Script

# Variables
PROJECT_NAME="quakewatch"
ENVIRONMENT="dev"
K3S_TOKEN="quakewatch-k3s-token-2025"

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
```

#### **k3s Master Configuration**
```yaml
# /etc/rancher/k3s/config.yaml
token: quakewatch-k3s-token-2025
cluster-init: true
disable:
  - traefik
  - servicelb
  - local-storage
  - metrics-server
write-kubeconfig-mode: "0644"
kubelet-arg:
  - "cloud-provider=external"
  - "provider-id=aws:///us-west-2a/i-1234567890abcdef0"
```

### **Step 2: Worker Node Installation**

#### **User Data Script Configuration**
```bash
#!/bin/bash
# k3s Worker Node User Data Script

# Variables
PROJECT_NAME="quakewatch"
ENVIRONMENT="dev"
K3S_TOKEN="quakewatch-k3s-token-2025"
K3S_SERVER="10.0.10.10"  # Master node private IP

# Update system
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y curl wget git vim htop jq

# Install k3s agent
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent" sh -s - \
    --token=${K3S_TOKEN} \
    --server=https://${K3S_SERVER}:6443 \
    --kubelet-arg="cloud-provider=external" \
    --kubelet-arg="provider-id=aws:///$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
```

#### **k3s Worker Configuration**
```yaml
# /etc/rancher/k3s/config.yaml
token: quakewatch-k3s-token-2025
server: https://10.0.10.10:6443
kubelet-arg:
  - "cloud-provider=external"
  - "provider-id=aws:///us-west-2a/i-0987654321fedcba0"
```

### **Step 3: Cloud Provider Integration**

#### **AWS Cloud Provider Configuration**
```bash
# Master node cloud provider setup
--kubelet-arg="cloud-provider=external" \
--kubelet-arg="provider-id=aws:///us-west-2a/i-1234567890abcdef0"

# Worker node cloud provider setup
--kubelet-arg="cloud-provider=external" \
--kubelet-arg="provider-id=aws:///us-west-2a/i-0987654321fedcba0"
```

#### **Provider ID Format**
```
aws:///<availability-zone>/<instance-id>
aws:///us-west-2a/i-1234567890abcdef0
```

### **Step 4: Network Configuration**

#### **Flannel CNI Configuration**
```yaml
# Flannel configuration (automatically configured)
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-flannel-cfg
  namespace: kube-system
data:
  cni-conf.json: |
    {
      "name": "cbr0",
      "cniVersion": "0.3.1",
      "plugins": [
        {
          "type": "flannel",
          "delegate": {
            "hairpinMode": true,
            "isDefaultGateway": true
          }
        }
      ]
    }
```

#### **VXLAN Configuration**
- **VXLAN Port**: 8472 (UDP)
- **Network**: 10.42.0.0/16 (default)
- **Backend**: VXLAN with host-gw fallback

## 🔧 **Installation Automation**

### **Terraform Provisioners**

#### **Master Node Provisioner**
```hcl
resource "null_resource" "k3s_master_setup" {
  count = var.k3s_master_count

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/quakewatch-key")
    host        = aws_instance.k3s_master[count.index].private_ip
    bastion_host = aws_instance.bastion[0].public_ip
    bastion_user = "ubuntu"
    bastion_private_key = file("~/.ssh/quakewatch-key")
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Setting up k3s master node ${count.index + 1}'",
      "sudo systemctl status k3s",
      "sudo kubectl get nodes"
    ]
  }
}
```

#### **Worker Node Provisioner**
```hcl
resource "null_resource" "k3s_worker_setup" {
  count = var.k3s_worker_count

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/quakewatch-key")
    host        = aws_instance.k3s_worker[count.index].private_ip
    bastion_host = aws_instance.bastion[0].public_ip
    bastion_user = "ubuntu"
    bastion_private_key = file("~/.ssh/quakewatch-key")
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Setting up k3s worker node ${count.index + 1}'",
      "sudo systemctl status k3s-agent"
    ]
  }
}
```

### **Installation Validation**

#### **Cluster Health Check**
```bash
#!/bin/bash
# k3s Cluster Health Check

echo "=== k3s Cluster Health Check ==="

# Check k3s service status
echo "1. k3s Service Status:"
sudo systemctl status k3s --no-pager

# Check cluster nodes
echo "2. Cluster Nodes:"
kubectl get nodes -o wide

# Check system pods
echo "3. System Pods:"
kubectl get pods -n kube-system

# Check cluster info
echo "4. Cluster Info:"
kubectl cluster-info

# Check k3s logs
echo "5. k3s Logs (last 20 lines):"
sudo journalctl -u k3s -n 20
```

## 📊 **k3s Configuration Details**

### **Master Node Configuration**

#### **k3s Server Options**
```bash
# k3s server installation command
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - \
    --token=quakewatch-k3s-token-2025 \
    --cluster-init \
    --disable=traefik \
    --disable=servicelb \
    --disable=local-storage \
    --disable=metrics-server \
    --write-kubeconfig-mode=644 \
    --kubelet-arg="cloud-provider=external" \
    --kubelet-arg="provider-id=aws:///us-west-2a/i-1234567890abcdef0"
```

#### **Configuration Options Explained**
- **`--token`**: Cluster token for node authentication
- **`--cluster-init`**: Initialize new cluster (for HA setup)
- **`--disable=traefik`**: Disable built-in Traefik ingress
- **`--disable=servicelb`**: Disable built-in service load balancer
- **`--disable=local-storage`**: Disable local storage provisioner
- **`--disable=metrics-server`**: Disable built-in metrics server
- **`--write-kubeconfig-mode=644`**: Set kubeconfig file permissions
- **`--kubelet-arg`**: Pass arguments to kubelet

### **Worker Node Configuration**

#### **k3s Agent Options**
```bash
# k3s agent installation command
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent" sh -s - \
    --token=quakewatch-k3s-token-2025 \
    --server=https://10.0.10.10:6443 \
    --kubelet-arg="cloud-provider=external" \
    --kubelet-arg="provider-id=aws:///us-west-2a/i-0987654321fedcba0"
```

#### **Configuration Options Explained**
- **`--token`**: Cluster token for authentication
- **`--server`**: Master node API server URL
- **`--kubelet-arg`**: Pass arguments to kubelet

## 🔍 **Installation Validation**

### **Validation Script**
```bash
#!/bin/bash
# k3s Installation Validation Script

echo "=== k3s Installation Validation ==="

# Check k3s service
echo "1. k3s Service Status:"
sudo systemctl is-active k3s
sudo systemctl is-enabled k3s

# Check k3s process
echo "2. k3s Process:"
ps aux | grep k3s

# Check k3s logs
echo "3. k3s Logs:"
sudo journalctl -u k3s --no-pager -l

# Check kubeconfig
echo "4. kubeconfig:"
sudo cat /etc/rancher/k3s/k3s.yaml

# Check cluster connectivity
echo "5. Cluster Connectivity:"
kubectl get nodes
kubectl get pods -A

# Check k3s data directory
echo "6. k3s Data Directory:"
sudo ls -la /var/lib/rancher/k3s/

# Check k3s configuration
echo "7. k3s Configuration:"
sudo cat /etc/rancher/k3s/config.yaml
```

### **Health Check Commands**
```bash
# Check k3s service status
sudo systemctl status k3s

# Check k3s logs
sudo journalctl -u k3s -f

# Check cluster nodes
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Check cluster info
kubectl cluster-info

# Check k3s data
sudo ls -la /var/lib/rancher/k3s/
```

## 🛠️ **Troubleshooting**

### **Common Installation Issues**

#### **1. k3s Service Not Starting**
```bash
# Check k3s service status
sudo systemctl status k3s

# Check k3s logs
sudo journalctl -u k3s -f

# Restart k3s service
sudo systemctl restart k3s

# Check k3s configuration
sudo cat /etc/rancher/k3s/config.yaml
```

#### **2. Worker Node Not Joining**
```bash
# Check worker node logs
sudo journalctl -u k3s-agent -f

# Check network connectivity
ping 10.0.10.10  # Master node IP
telnet 10.0.10.10 6443  # k3s API port

# Check token
sudo cat /etc/rancher/k3s/config.yaml
```

#### **3. Cloud Provider Issues**
```bash
# Check provider ID
kubectl get nodes -o yaml | grep providerID

# Check cloud provider logs
kubectl logs -n kube-system -l app=cloud-controller-manager

# Check AWS metadata
curl http://169.254.169.254/latest/meta-data/instance-id
curl http://169.254.169.254/latest/meta-data/placement/availability-zone
```

### **Debug Commands**
```bash
# Check k3s service
sudo systemctl status k3s
sudo systemctl status k3s-agent

# Check k3s logs
sudo journalctl -u k3s -f
sudo journalctl -u k3s-agent -f

# Check k3s configuration
sudo cat /etc/rancher/k3s/config.yaml
sudo cat /etc/rancher/k3s/k3s.yaml

# Check k3s data
sudo ls -la /var/lib/rancher/k3s/
sudo ls -la /etc/rancher/k3s/

# Check network
ip route show
ip addr show
netstat -tlnp | grep 6443
```

## 📚 **Best Practices**

### **Security**
- **Token Management**: Use strong, unique tokens
- **Network Security**: Proper security groups
- **Access Control**: RBAC configuration
- **Encryption**: Encrypted communication

### **Performance**
- **Resource Limits**: Appropriate instance sizes
- **Storage**: Fast storage for etcd
- **Networking**: Optimized network configuration
- **Monitoring**: Comprehensive monitoring

### **Reliability**
- **High Availability**: Multi-master setup
- **Backup**: Regular etcd backups
- **Health Checks**: Application and infrastructure monitoring
- **Disaster Recovery**: Recovery procedures

## 🎯 **Conclusion**

The k3s installation process provides a lightweight, production-ready Kubernetes cluster with:

- ✅ **Automated Installation**: Terraform provisioners and user data scripts
- ✅ **Cloud Integration**: AWS cloud provider for load balancers and storage
- ✅ **High Availability**: Multi-master and multi-worker setup
- ✅ **Security**: Proper network segmentation and access control
- ✅ **Monitoring**: Comprehensive health checks and validation
- ✅ **Scalability**: Easy addition of worker nodes

The installation is fully automated and production-ready for the QuakeWatch application.
