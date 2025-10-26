# AWS Infrastructure Documentation for QuakeWatch k3s Cluster

## Overview

This document provides comprehensive documentation for the AWS infrastructure supporting the QuakeWatch k3s cluster, including VPC configuration, EC2 instances, security groups, IAM roles, and the complete deployment process.

## 🏗️ **Infrastructure Architecture**

### **High-Level Architecture**
```
┌─────────────────────────────────────────────────────────────────┐
│                           Internet                              │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                    Internet Gateway                            │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                    Public Subnets (Multi-AZ)                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   Bastion   │  │     ALB     │  │   NAT GW    │            │
│  │    Host     │  │             │  │             │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                   Private Subnets (Multi-AZ)                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │ k3s Master  │  │ k3s Worker  │  │ k3s Worker  │            │
│  │             │  │             │  │             │            │
│  │ QuakeWatch  │  │ QuakeWatch  │  │ QuakeWatch  │            │
│  │   Pods      │  │   Pods      │  │   Pods      │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

## 📋 **Terraform Configuration Files**

### **Core Infrastructure Files**

#### **1. main.tf - Provider Configuration**
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
```

#### **2. vpc.tf - VPC and Networking**
- **VPC**: 10.0.0.0/16 CIDR block
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24
- **Private Subnets**: 10.0.10.0/24, 10.0.20.0/24
- **Database Subnets**: 10.0.30.0/24, 10.0.40.0/24
- **Internet Gateway**: For public subnet internet access
- **NAT Gateways**: For private subnet internet access
- **VPC Endpoints**: For AWS services (S3, ECR, ECS)

#### **3. security-groups.tf - Security Groups**
- **Bastion SG**: SSH access from allowed IPs
- **k3s Master SG**: k3s API, etcd, node communication
- **k3s Worker SG**: kubelet and node communication
- **ALB SG**: HTTP/HTTPS access from internet
- **RDS SG**: Database access from k3s nodes
- **VPC Endpoints SG**: HTTPS access for AWS services

#### **4. iam.tf - IAM Roles and Policies**
- **k3s Master Role**: EC2, ECR, S3, CloudWatch, Secrets Manager
- **k3s Worker Role**: EC2, ECR, S3, CloudWatch
- **Bastion Role**: EC2, SSM, CloudWatch
- **Instance Profiles**: For EC2 instances

#### **5. ec2.tf - EC2 Instances and Load Balancer**
- **Bastion Host**: t2.micro (public subnet)
- **k3s Master**: t3.medium (private subnet)
- **k3s Workers**: t3.large (private subnet)
- **Application Load Balancer**: For external access
- **S3 Bucket**: For k3s backups

#### **6. provisioners.tf - k3s Installation Automation**
- **Remote-exec provisioners**: For k3s installation
- **Local-exec provisioners**: For validation and setup
- **Cluster validation**: Comprehensive health checks

## 🌐 **VPC Configuration Details**

### **Network Architecture**

#### **VPC Configuration**
```hcl
resource "aws_vpc" "quakewatch_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "quakewatch-vpc"
    Environment = "dev"
    Project     = "QuakeWatch"
  }
}
```

#### **Subnet Configuration**
- **Public Subnets**: For bastion host, ALB, and NAT gateways
- **Private Subnets**: For k3s master and worker nodes
- **Database Subnets**: For RDS and ElastiCache (future use)
- **Multi-AZ**: High availability across availability zones

#### **Routing Configuration**
- **Public Route Table**: Routes to Internet Gateway
- **Private Route Tables**: Routes to NAT Gateways
- **Database Route Table**: No internet access

### **Security Groups**

#### **Bastion Security Group**
```hcl
resource "aws_security_group" "bastion" {
  name_prefix = "quakewatch-bastion-"
  vpc_id      = aws_vpc.quakewatch_vpc.id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

#### **k3s Master Security Group**
```hcl
resource "aws_security_group" "k3s_master" {
  name_prefix = "quakewatch-k3s-master-"
  vpc_id      = aws_vpc.quakewatch_vpc.id
  
  # k3s API server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  # etcd communication
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  # kubelet API
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
}
```

## 🖥️ **EC2 Instances Configuration**

### **Instance Types and Sizing**

#### **Bastion Host**
- **Instance Type**: t2.micro (free tier) or t3.micro
- **Storage**: 8GB GP3 (free tier) or 20GB
- **Network**: Public subnet
- **Purpose**: Secure access to private instances

#### **k3s Master Node**
- **Instance Type**: t3.medium (2 vCPU, 4GB RAM)
- **Storage**: 50GB GP3 root + 100GB GP3 data
- **Network**: Private subnet
- **Purpose**: k3s control plane

#### **k3s Worker Nodes**
- **Instance Type**: t3.large (2 vCPU, 8GB RAM)
- **Storage**: 50GB GP3 root + 200GB GP3 data
- **Network**: Private subnet
- **Purpose**: Application workloads

### **User Data Scripts**

#### **Bastion Host Setup**
```bash
#!/bin/bash
# Bastion host configuration
apt-get update -y
apt-get install -y curl wget git vim htop jq kubectl helm

# Create project directory
mkdir -p /opt/quakewatch

# Configure SSH for k3s access
cat > /home/ubuntu/.ssh/config << EOF
Host k3s-*
    User ubuntu
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
EOF
```

#### **k3s Master Setup**
```bash
#!/bin/bash
# k3s master installation
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - \
    --token=${K3S_TOKEN} \
    --cluster-init \
    --disable=traefik \
    --disable=servicelb \
    --write-kubeconfig-mode=644

# Deploy QuakeWatch
kubectl create namespace quakewatch
kubectl apply -f /opt/quakewatch/k8s/ -n quakewatch
```

#### **k3s Worker Setup**
```bash
#!/bin/bash
# k3s worker installation
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent" sh -s - \
    --token=${K3S_TOKEN} \
    --server=https://${K3S_SERVER}:6443
```

## 🔐 **IAM Roles and Policies**

### **k3s Master IAM Role**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeRegions",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::quakewatch-*",
        "arn:aws:s3:::quakewatch-*/*"
      ]
    }
  ]
}
```

### **k3s Worker IAM Role**
- **EC2 Permissions**: Describe instances, volumes, tags
- **ECR Permissions**: Pull container images
- **S3 Permissions**: Access backup bucket
- **CloudWatch Permissions**: Send logs and metrics

## 🚀 **k3s Installation Process**

### **Installation Steps**

#### **1. Master Node Installation**
```bash
# Install k3s server
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

#### **2. Worker Node Installation**
```bash
# Install k3s agent
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent" sh -s - \
    --token=quakewatch-k3s-token-2025 \
    --server=https://10.0.10.10:6443 \
    --kubelet-arg="cloud-provider=external" \
    --kubelet-arg="provider-id=aws:///us-west-2a/i-0987654321fedcba0"
```

#### **3. Cloud Provider Integration**
- **AWS Cloud Provider**: For load balancer and storage integration
- **Provider ID**: Unique identifier for each node
- **Availability Zone**: Node placement information

### **k3s Configuration**

#### **Master Node Configuration**
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

#### **Worker Node Configuration**
```yaml
# /etc/rancher/k3s/config.yaml
token: quakewatch-k3s-token-2025
server: https://10.0.10.10:6443
kubelet-arg:
  - "cloud-provider=external"
  - "provider-id=aws:///us-west-2a/i-0987654321fedcba0"
```

## 📊 **Load Balancer Configuration**

### **Application Load Balancer**
```hcl
resource "aws_lb" "k3s_alb" {
  name               = "quakewatch-k3s-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public_subnets[*].id
}
```

### **Target Groups**
- **k3s API Target Group**: Port 6443 for k3s API server
- **QuakeWatch Target Group**: Port 80 for application access

### **Listeners**
- **HTTP Listener**: Port 80 for QuakeWatch application
- **HTTPS Listener**: Port 443 for SSL/TLS termination

## 🔍 **Monitoring and Logging**

### **CloudWatch Integration**
- **Instance Metrics**: CPU, memory, disk usage
- **Custom Metrics**: Application-specific metrics
- **Log Groups**: Centralized logging
- **Alarms**: Automated alerting

### **S3 Backup Configuration**
```hcl
resource "aws_s3_bucket" "k3s_backups" {
  bucket = "quakewatch-k3s-backups-${random_string.bucket_suffix.result}"
  
  versioning {
    enabled = true
  }
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
```

## 💰 **Cost Optimization**

### **Free Tier Usage**
- **EC2**: t2.micro instances (750 hours/month)
- **EBS**: 30GB storage (free tier)
- **S3**: 5GB storage (free tier)
- **ALB**: 750 hours/month (free tier)

### **Cost Optimization Strategies**
- **Right-sizing**: Appropriate instance types
- **Reserved Instances**: For predictable workloads
- **Spot Instances**: For non-critical workloads
- **Storage Optimization**: GP3 volumes, lifecycle policies

## 🔧 **Deployment Process**

### **Step 1: Infrastructure Deployment**
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply
```

### **Step 2: k3s Installation**
- **Automated**: User data scripts install k3s
- **Validation**: Provisioners verify installation
- **Configuration**: Cloud provider integration

### **Step 3: QuakeWatch Deployment**
- **Namespace**: Create quakewatch namespace
- **Application**: Deploy QuakeWatch pods
- **Services**: Configure ClusterIP and NodePort
- **Ingress**: Set up external access

### **Step 4: Validation**
```bash
# Check cluster status
kubectl get nodes
kubectl get pods -A

# Check QuakeWatch
kubectl get pods -n quakewatch
kubectl get svc -n quakewatch

# Test access
curl http://<alb-dns-name>
```

## 🛠️ **Troubleshooting**

### **Common Issues**

#### **1. k3s Installation Issues**
```bash
# Check k3s service
sudo systemctl status k3s
sudo journalctl -u k3s -f

# Check k3s configuration
sudo cat /etc/rancher/k3s/k3s.yaml
```

#### **2. Network Connectivity Issues**
```bash
# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>

# Check route tables
aws ec2 describe-route-tables --route-table-ids <rt-id>
```

#### **3. IAM Permission Issues**
```bash
# Check instance profile
aws sts get-caller-identity

# Check IAM role
aws iam get-role --role-name quakewatch-k3s-master-role
```

### **Debug Commands**
```bash
# Cluster info
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -A -o wide

# QuakeWatch specific
kubectl get all -n quakewatch
kubectl logs -n quakewatch -l app=quakewatch
kubectl describe pod -n quakewatch -l app=quakewatch
```

## 📚 **Best Practices**

### **Security**
- **Network Segmentation**: Private subnets for k3s nodes
- **Security Groups**: Least privilege access
- **IAM Roles**: Minimal required permissions
- **Encryption**: Encrypted EBS volumes

### **Performance**
- **Right-sizing**: Appropriate instance types
- **Storage**: GP3 volumes for better performance
- **Networking**: VPC endpoints to reduce NAT costs
- **Monitoring**: Comprehensive metrics and logging

### **Reliability**
- **Multi-AZ**: High availability across zones
- **Backup**: Regular S3 backups
- **Health Checks**: Application and infrastructure monitoring
- **Disaster Recovery**: Recovery procedures and testing

## 🎯 **Conclusion**

This AWS infrastructure provides a robust, scalable, and secure foundation for the QuakeWatch k3s cluster. The configuration includes:

- ✅ **Complete VPC Setup**: Multi-AZ networking with proper segmentation
- ✅ **Secure EC2 Instances**: Right-sized instances with proper IAM roles
- ✅ **Automated k3s Installation**: User data scripts and provisioners
- ✅ **External Access**: ALB and NodePort for application access
- ✅ **Monitoring**: CloudWatch integration and S3 backups
- ✅ **Cost Optimization**: Free tier usage and cost-effective design

The infrastructure is production-ready with proper security, monitoring, and scalability features.
