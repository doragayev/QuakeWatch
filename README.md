# QuakeWatch - DevOps Project

## 🌍 **Project Overview**

QuakeWatch is a real-time earthquake monitoring application deployed on AWS using k3s Kubernetes cluster with comprehensive DevOps practices including Infrastructure as Code, GitOps, monitoring, and automation.

## 📁 **Project Structure**

```
QuakeWatch/
├── 📁 applications/                 # Application Components
│   ├── 📁 docker/                  # Docker Configuration
│   │   ├── Dockerfile              # Container definition
│   │   ├── requirements.txt        # Python dependencies
│   │   ├── app.py                  # Flask application
│   │   ├── dashboard.py            # Dashboard module
│   │   ├── utils.py                # Utility functions
│   │   └── metrics.py              # Prometheus metrics
│   ├── 📁 helm/                    # Helm Charts
│   │   └── 📁 quakewatch/          # QuakeWatch Helm chart
│   │       ├── Chart.yaml          # Chart metadata
│   │       ├── values.yaml         # Chart values
│   │       └── 📁 templates/        # Helm templates
│   └── 📁 k8s/                     # Kubernetes Manifests
│       ├── deployment.yaml         # Application deployment
│       ├── service.yaml            # ClusterIP service
│       ├── nodeport.yaml           # NodePort service
│       ├── ingress.yaml            # Ingress configuration
│       ├── configmap.yaml          # Application config
│       ├── hpa.yaml                # Horizontal Pod Autoscaler
│       └── 📁 argocd/               # ArgoCD Applications
│           ├── quakewatch-app.yaml
│           ├── monitoring-app.yaml
│           └── alerting-app.yaml
├── 📁 infrastructure/              # Infrastructure as Code
│   └── 📁 terraform/               # Terraform Configuration
│       ├── main.tf                 # Provider configuration
│       ├── vpc.tf                  # VPC and networking
│       ├── security-groups.tf      # Security groups
│       ├── iam.tf                  # IAM roles and policies
│       ├── ec2.tf                  # EC2 instances and ALB
│       ├── provisioners.tf         # k3s installation automation
│       ├── variables.tf            # Input variables
│       ├── outputs.tf              # Output values
│       ├── 📁 scripts/             # User data scripts
│       │   ├── k3s-master-userdata.sh
│       │   ├── k3s-worker-userdata.sh
│       │   ├── bastion-userdata.sh
│       │   ├── deploy-quakewatch.sh
│       │   └── validate-cluster.sh
│       └── 📁 docs/                 # Infrastructure documentation
│           ├── AWS_INFRASTRUCTURE_DOCUMENTATION.md
│           ├── K3S_DEPLOYMENT_GUIDE.md
│           ├── K3S_INSTALLATION_GUIDE.md
│           ├── FREE_TIER_SETUP.md
│           └── README.md
├── 📁 monitoring/                  # Monitoring Stack
│   └── 📁 prometheus/              # Prometheus & Grafana
│       ├── prometheus-alerts.yaml  # Alert rules
│       ├── alertmanager-config.yaml # AlertManager config
│       └── 📁 grafana-dashboards/   # Grafana dashboards
│           ├── quakewatch-application-dashboard.json
│           ├── cluster-health-dashboard.json
│           └── system-overview-dashboard.json
├── 📁 docs/                        # Documentation
│   ├── PROJECT_DELIVERABLES.md    # Complete deliverables overview
│   ├── 📁 architecture/            # Architecture documentation
│   ├── 📁 deployment/              # Deployment guides
│   └── 📁 operations/              # Operations documentation
│       ├── MONITORING_DOCUMENTATION.md
│       ├── DASHBOARD_SAMPLES.md
│       ├── TROUBLESHOOTING_GUIDE.md
│       ├── ALERTING_GUIDE.md
│       └── README_MONITORING.md
└── 📁 scripts/                     # Utility Scripts
    ├── import-dashboards.sh       # Dashboard import
    ├── test-alerts.sh             # Alert testing
    └── alert-webhook-receiver.py  # Alert webhook
```

## 🚀 **Quick Start**

### **Prerequisites**
- AWS Account with appropriate permissions
- Terraform >= 1.0
- kubectl
- Helm 3.x

### **1. Deploy Infrastructure**
```bash
cd infrastructure/terraform
cp terraform.tfvars.free-tier terraform.tfvars
# Edit terraform.tfvars with your details
terraform init
terraform plan
terraform apply
```

### **2. Access Your Cluster**
```bash
# Get connection information
terraform output

# SSH to bastion host
ssh -i ~/.ssh/quakewatch-key ubuntu@$(terraform output -raw bastion_public_ip)
```

### **3. Deploy QuakeWatch**
```bash
# Deploy using Kubernetes manifests
kubectl apply -f applications/k8s/

# Or deploy using Helm
helm install quakewatch applications/helm/quakewatch
```

## 🏗️ **Architecture**

### **Infrastructure**
- **AWS VPC**: Multi-AZ setup with public/private subnets
- **k3s Cluster**: Lightweight Kubernetes cluster
- **Application Load Balancer**: External access
- **Security Groups**: Network segmentation
- **IAM Roles**: Minimal required permissions

### **Application**
- **QuakeWatch**: Flask-based earthquake monitoring
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **ArgoCD**: GitOps continuous deployment

## 📊 **Features**

### **✅ Infrastructure as Code**
- Complete Terraform configuration
- Automated k3s installation
- Security best practices
- Cost optimization

### **✅ GitOps Deployment**
- ArgoCD for continuous deployment
- Git-based configuration management
- Automated sync and self-healing

### **✅ Monitoring & Observability**
- Prometheus metrics collection
- Grafana dashboards
- AlertManager notifications
- Comprehensive health checks

### **✅ Security**
- Network segmentation
- IAM roles with least privilege
- Encrypted storage
- Security contexts

## 🌐 **Access Methods**

### **External Access**
1. **NodePort**: `http://<node-ip>:30000`
2. **ALB**: `http://<alb-dns-name>`
3. **Port-Forward**: `kubectl port-forward -n quakewatch svc/quakewatch 8080:80`

### **Monitoring Access**
- **Grafana**: http://localhost:3000 (admin/prom-operator)
- **Prometheus**: http://localhost:9090
- **AlertManager**: http://localhost:9093

## 💰 **Cost Optimization**

### **Free Tier Usage**
- **EC2**: t2.micro instances (750 hours/month)
- **EBS**: 30GB storage (free tier)
- **S3**: 5GB storage (free tier)
- **ALB**: 750 hours/month (free tier)

## 📚 **Documentation**

### **Architecture**
- [AWS Infrastructure Documentation](infrastructure/terraform/docs/AWS_INFRASTRUCTURE_DOCUMENTATION.md)
- [k3s Deployment Guide](infrastructure/terraform/docs/K3S_DEPLOYMENT_GUIDE.md)
- [k3s Installation Guide](infrastructure/terraform/docs/K3S_INSTALLATION_GUIDE.md)

### **Operations**
- [Monitoring Documentation](docs/operations/MONITORING_DOCUMENTATION.md)
- [Troubleshooting Guide](docs/operations/TROUBLESHOOTING_GUIDE.md)
- [Alerting Guide](docs/operations/ALERTING_GUIDE.md)

### **Deployment**
- [GitOps Deployment Guide](docs/deployment/GITOPS_DEPLOYMENT_GUIDE.md)
- [Free Tier Setup](infrastructure/terraform/docs/FREE_TIER_SETUP.md)

## 🔧 **Troubleshooting**

### **Common Issues**
1. **k3s Installation**: Check service status and logs
2. **Network Connectivity**: Verify security groups
3. **QuakeWatch Access**: Check pods and services
4. **IAM Permissions**: Verify instance profiles

### **Debug Commands**
```bash
# Check cluster status
kubectl get nodes
kubectl get pods -A
kubectl get svc -A

# Check QuakeWatch
kubectl get all -n quakewatch
kubectl logs -n quakewatch -l app=quakewatch
```

## 🎯 **Project Deliverables**

### **✅ Infrastructure**
- Complete Terraform configuration
- AWS VPC and EC2 setup
- Security groups and IAM roles
- Load balancer configuration

### **✅ Application**
- Kubernetes manifests
- Helm charts
- Docker configuration
- GitOps setup

### **✅ Monitoring**
- Prometheus configuration
- Grafana dashboards
- AlertManager setup
- Comprehensive documentation

## 📈 **Next Steps**

1. **Production Deployment**: Scale to production environment
2. **CI/CD Pipeline**: Implement automated testing and deployment
3. **Security Hardening**: Additional security measures
4. **Disaster Recovery**: Backup and recovery procedures

## 🤝 **Contributing**

This project demonstrates advanced DevOps practices including:
- Infrastructure as Code
- GitOps
- Monitoring and Observability
- Security best practices
- Cost optimization
- Automation

## 📄 **License**

This project is for educational and demonstration purposes.

---

**QuakeWatch DevOps Project** - A comprehensive demonstration of modern DevOps practices with AWS, Kubernetes, and monitoring.