# AWS Free Tier Setup Guide for QuakeWatch

## 🆓 **Free Tier Resources Used**

### **What's FREE in AWS Free Tier:**
- **EC2**: 750 hours/month of t2.micro instances (1 instance running 24/7)
- **EBS**: 30 GB of General Purpose (SSD) storage
- **S3**: 5 GB of standard storage
- **Load Balancer**: 750 hours/month of Application Load Balancer
- **NAT Gateway**: 1 GB of data processing
- **VPC**: No additional charges for VPC, subnets, security groups

### **Free Tier Configuration:**
- **Instances**: t2.micro (1 master + 1 worker + 1 bastion)
- **Storage**: 8GB per instance (within 30GB free tier)
- **No additional EBS volumes**
- **Minimal NAT Gateway usage**

## 📋 **Prerequisites**

### 1. **AWS Account Setup**
1. Create AWS account at https://aws.amazon.com
2. Complete account verification
3. Set up billing alerts (to monitor usage)

### 2. **Generate SSH Key Pair**
```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/quakewatch-key

# Copy public key
cat ~/.ssh/quakewatch-key.pub
```

### 3. **Install Required Tools**
```bash
# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

## 🚀 **Step-by-Step Setup**

### **Step 1: Configure AWS CLI**
```bash
# Configure AWS credentials
aws configure

# Enter your credentials:
# AWS Access Key ID: [Your Access Key]
# AWS Secret Access Key: [Your Secret Key]
# Default region name: us-west-2
# Default output format: json
```

### **Step 2: Prepare Terraform Configuration**
```bash
# Navigate to terraform directory
cd terraform

# Copy free tier configuration
cp terraform.tfvars.free-tier terraform.tfvars

# Edit configuration with your details
nano terraform.tfvars
```

### **Step 3: Update Configuration**
Edit `terraform.tfvars` with your details:

```hcl
# Replace with your SSH public key
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... your-actual-public-key"

# Replace with your IP address
allowed_ssh_cidrs = ["YOUR_ACTUAL_IP/32"]
```

### **Step 4: Deploy Infrastructure**
```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply configuration
terraform apply
```

### **Step 5: Access Your Cluster**
```bash
# Get connection information
terraform output

# SSH to bastion host
ssh -i ~/.ssh/quakewatch-key ubuntu@$(terraform output -raw bastion_public_ip)

# From bastion, SSH to k3s master
ssh -i ~/.ssh/quakewatch-key ubuntu@<master-private-ip>
```

## 💰 **Free Tier Cost Breakdown**

### **Monthly Costs (FREE):**
- **EC2 t2.micro**: 750 hours/month (FREE)
- **EBS Storage**: 30GB/month (FREE)
- **S3 Storage**: 5GB/month (FREE)
- **ALB**: 750 hours/month (FREE)
- **NAT Gateway**: 1GB data processing (FREE)
- **VPC**: No additional cost (FREE)

### **Total Monthly Cost: $0.00** 🎉

## ⚠️ **Free Tier Limitations**

### **Resource Limits:**
- **Only 1 t2.micro instance** (we use 3, but 2 will be stopped when not needed)
- **30GB EBS storage total**
- **5GB S3 storage**
- **Limited NAT Gateway usage**

### **Workarounds:**
1. **Stop instances when not in use**
2. **Use single instance for testing**
3. **Minimize storage usage**
4. **Monitor usage in AWS Console**

## 🔧 **Free Tier Optimizations**

### **1. Single Instance Setup**
For maximum free tier usage, use only 1 instance:

```hcl
# In terraform.tfvars
k3s_master_count = 1
k3s_worker_count = 0  # No workers
create_bastion = false  # No bastion
```

### **2. Minimal Storage**
```hcl
k3s_master_volume_size = 8
k3s_master_data_volume_size = 0
k3s_worker_data_volume_size = 0
```

### **3. Cost Monitoring**
Set up billing alerts:
1. Go to AWS Billing Console
2. Set up billing alerts
3. Monitor usage daily

## 🛠️ **Alternative: Local Development**

If you want to avoid AWS costs entirely, you can run locally:

### **Option 1: Minikube**
```bash
# Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start minikube
minikube start

# Deploy QuakeWatch
kubectl apply -f k8s/
```

### **Option 2: Docker Desktop**
```bash
# Install Docker Desktop
# Enable Kubernetes in Docker Desktop
# Deploy QuakeWatch
kubectl apply -f k8s/
```

## 📊 **Free Tier Monitoring**

### **Check Usage:**
```bash
# Check EC2 usage
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name]'

# Check EBS usage
aws ec2 describe-volumes --query 'Volumes[*].[VolumeId,Size,VolumeType]'

# Check S3 usage
aws s3 ls s3://your-bucket-name
```

### **AWS Console Monitoring:**
1. Go to AWS Billing Console
2. Check "Free Tier" tab
3. Monitor usage daily
4. Set up billing alerts

## 🚨 **Important Notes**

### **Free Tier Expiration:**
- Free tier lasts for **12 months** from account creation
- After 12 months, you'll be charged for resources
- Monitor usage to avoid unexpected charges

### **Resource Management:**
- **Stop instances** when not in use
- **Delete resources** when done testing
- **Use AWS Console** to monitor usage
- **Set up billing alerts**

### **Cost Control:**
```bash
# Stop all instances
aws ec2 stop-instances --instance-ids i-1234567890abcdef0

# Start instances when needed
aws ec2 start-instances --instance-ids i-1234567890abcdef0

# Terminate when done
terraform destroy
```

## 🎯 **Recommended Approach**

### **For Learning/Testing:**
1. Use **local minikube** for development
2. Use **AWS free tier** for production-like testing
3. **Stop instances** when not in use
4. **Monitor costs** regularly

### **For Production:**
1. Use **proper instance types** (t3.small+)
2. Use **multiple AZs** for HA
3. Use **proper storage** (gp3)
4. Use **reserved instances** for cost savings

## 📞 **Support**

If you encounter issues:
1. Check AWS Free Tier usage
2. Verify billing alerts
3. Review resource limits
4. Contact AWS support (free tier users get support)

Remember: **Always monitor your AWS usage to avoid unexpected charges!** 💰
