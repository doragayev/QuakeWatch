# QuakeWatch AWS Infrastructure with Terraform

## Overview

This Terraform configuration provisions a complete AWS infrastructure for hosting the QuakeWatch k3s cluster. The infrastructure includes VPC, networking, security groups, EC2 instances, load balancers, and all necessary IAM roles and policies.

## Architecture

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
│                    Public Subnets                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   Bastion   │  │     ALB     │  │   NAT GW    │            │
│  │    Host     │  │             │  │             │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                   Private Subnets                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │ k3s Master  │  │ k3s Worker  │  │ k3s Worker  │            │
│  │             │  │             │  │             │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

## Features

### ✅ **VPC and Networking**
- Multi-AZ VPC with public, private, and database subnets
- Internet Gateway and NAT Gateways for internet access
- VPC Endpoints for AWS services (S3, ECR, ECS)
- Route tables and security groups

### ✅ **k3s Cluster**
- High-availability k3s master nodes
- Scalable worker nodes
- Proper IAM roles and policies
- Cloud provider integration

### ✅ **Security**
- Network segmentation with private subnets
- Security groups with least privilege access
- IAM roles with minimal required permissions
- Encrypted EBS volumes

### ✅ **Load Balancing**
- Application Load Balancer for external access
- Target groups for k3s API and QuakeWatch application
- SSL/TLS termination support

### ✅ **Monitoring and Backup**
- S3 bucket for k3s backups
- CloudWatch integration
- Comprehensive logging

## Prerequisites

### Required Tools
- Terraform >= 1.0
- AWS CLI configured
- SSH key pair
- kubectl (for cluster management)

### AWS Requirements
- AWS Account with appropriate permissions
- EC2, VPC, IAM, S3, and ALB permissions
- Key pair for SSH access

## Quick Start

### 1. Configure Variables

Create `terraform.tfvars` file:

```hcl
# Project Configuration
project_name = "quakewatch"
environment  = "dev"

# AWS Configuration
aws_region = "us-west-2"

# SSH Configuration
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... your-public-key"

# k3s Configuration
k3s_master_count = 1
k3s_worker_count = 2
k3s_master_instance_type = "t3.medium"
k3s_worker_instance_type = "t3.large"

# Security
allowed_ssh_cidrs = ["YOUR_IP/32"]

# SSL (optional)
ssl_certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply
```

### 3. Access Your Cluster

```bash
# Get connection information
terraform output

# SSH to bastion host
ssh -i ~/.ssh/id_rsa ubuntu@$(terraform output -raw bastion_public_ip)

# From bastion, SSH to k3s master
ssh ubuntu@<master-private-ip>

# Copy kubeconfig
sudo cat /etc/rancher/k3s/k3s.yaml
```

## Configuration Files

### Core Files
- `main.tf` - Provider configuration and data sources
- `vpc.tf` - VPC, subnets, and networking
- `security-groups.tf` - Security groups and rules
- `iam.tf` - IAM roles and policies
- `ec2.tf` - EC2 instances and load balancers
- `variables.tf` - Input variables
- `outputs.tf` - Output values

### User Data Scripts
- `scripts/bastion-userdata.sh` - Bastion host setup
- `scripts/k3s-master-userdata.sh` - k3s master setup
- `scripts/k3s-worker-userdata.sh` - k3s worker setup

## Infrastructure Components

### VPC Configuration
- **CIDR**: 10.0.0.0/16
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24
- **Private Subnets**: 10.0.10.0/24, 10.0.20.0/24
- **Database Subnets**: 10.0.30.0/24, 10.0.40.0/24

### Security Groups
- **Bastion**: SSH access from allowed IPs
- **k3s Master**: k3s API, etcd, and node communication
- **k3s Worker**: kubelet and node communication
- **ALB**: HTTP/HTTPS access from internet
- **RDS**: Database access from k3s nodes

### IAM Roles
- **k3s Master**: EC2, ECR, S3, CloudWatch, Secrets Manager
- **k3s Worker**: EC2, ECR, S3, CloudWatch
- **Bastion**: EC2, SSM, CloudWatch

### EC2 Instances
- **Bastion**: t3.micro (public subnet)
- **k3s Master**: t3.medium (private subnet)
- **k3s Worker**: t3.large (private subnet)

## Network Architecture

### Public Subnets
- Internet Gateway for outbound access
- Bastion host for secure access
- Application Load Balancer
- NAT Gateways for private subnet internet access

### Private Subnets
- k3s master and worker nodes
- No direct internet access
- Outbound via NAT Gateways
- VPC Endpoints for AWS services

### Database Subnets
- Isolated for RDS/ElastiCache
- No internet access
- Access only from k3s nodes

## Security Features

### Network Security
- Private subnets for k3s nodes
- Security groups with least privilege
- No direct internet access to k3s nodes
- VPC Endpoints to reduce NAT Gateway costs

### Instance Security
- Encrypted EBS volumes
- IAM roles with minimal permissions
- Security groups restricting access
- Regular security updates via user data

### Access Control
- SSH access only through bastion
- k3s API access through ALB
- Application access through ALB
- No direct access to k3s nodes

## Monitoring and Logging

### CloudWatch Integration
- Instance metrics and logs
- Custom metrics for k3s
- Log aggregation
- Cost monitoring

### Backup Strategy
- S3 bucket for k3s backups
- Automated backup scripts
- Lifecycle policies for cost optimization
- Cross-region replication (optional)

## Cost Optimization

### Instance Types
- Right-sized instances for workload
- Spot instances for non-critical workloads
- Reserved instances for predictable workloads

### Storage
- GP3 volumes for better performance/cost
- Lifecycle policies for S3 backups
- Volume optimization

### Networking
- VPC Endpoints to reduce NAT costs
- Single NAT Gateway for cost savings
- Efficient security group rules

## Troubleshooting

### Common Issues

#### 1. k3s Not Starting
```bash
# Check k3s service status
sudo systemctl status k3s

# Check k3s logs
sudo journalctl -u k3s -f

# Check k3s configuration
sudo cat /etc/rancher/k3s/k3s.yaml
```

#### 2. Network Connectivity
```bash
# Test internet connectivity
curl -I https://google.com

# Test k3s API
curl -k https://localhost:6443/version

# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>
```

#### 3. IAM Issues
```bash
# Check instance profile
aws sts get-caller-identity

# Check IAM permissions
aws iam get-role --role-name <role-name>
```

### Debugging Commands

```bash
# Check Terraform state
terraform state list
terraform state show <resource>

# Check AWS resources
aws ec2 describe-instances --filters "Name=tag:Project,Values=quakewatch"
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=quakewatch"

# Check k3s cluster
kubectl get nodes
kubectl get pods -A
kubectl get svc -A
```

## Maintenance

### Regular Tasks
- Update AMI images
- Rotate SSH keys
- Review security groups
- Monitor costs
- Update k3s version

### Backup Procedures
- Automated k3s backups to S3
- Configuration backup
- State file backup
- Documentation updates

### Scaling
- Add worker nodes: Update `k3s_worker_count`
- Change instance types: Update instance type variables
- Add master nodes: Update `k3s_master_count`

## Security Considerations

### Network Security
- Private subnets for k3s nodes
- Security groups with minimal access
- No direct internet access to k3s nodes
- VPC Endpoints for AWS services

### Access Control
- SSH access only through bastion
- IAM roles with least privilege
- Regular access reviews
- Multi-factor authentication

### Data Protection
- Encrypted EBS volumes
- Encrypted S3 buckets
- Secure key management
- Regular security updates

## Cost Estimation

### Monthly Costs (us-west-2)
- **Bastion (t3.micro)**: ~$8
- **k3s Master (t3.medium)**: ~$30
- **k3s Workers (2x t3.large)**: ~$120
- **ALB**: ~$20
- **NAT Gateway**: ~$45
- **EBS Storage**: ~$20
- **S3 Backups**: ~$5
- **Total**: ~$248/month

### Cost Optimization Tips
- Use Spot instances for workers
- Right-size instances based on usage
- Use VPC Endpoints to reduce NAT costs
- Implement S3 lifecycle policies
- Use Reserved Instances for predictable workloads

## Next Steps

1. **Deploy QuakeWatch Application**
   - Use ArgoCD for GitOps deployment
   - Configure monitoring with Prometheus/Grafana
   - Set up alerting rules

2. **Configure Monitoring**
   - Deploy Prometheus and Grafana
   - Set up CloudWatch integration
   - Configure alerting

3. **Security Hardening**
   - Enable AWS Config
   - Set up CloudTrail
   - Implement WAF
   - Regular security scans

4. **Backup and DR**
   - Cross-region backups
   - Disaster recovery procedures
   - Regular restore testing

## Support

For issues or questions:
1. Check Terraform documentation
2. Review AWS documentation
3. Check k3s documentation
4. Review troubleshooting guide

## License

This infrastructure code is provided as-is for educational and development purposes.
