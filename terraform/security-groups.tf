# Security Groups for QuakeWatch k3s Cluster
# This file defines all security groups and their rules

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.project_name}-vpc-endpoints-"
  vpc_id      = aws_vpc.quakewatch_vpc.id
  description = "Security group for VPC endpoints"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-vpc-endpoints-sg"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "VPC Endpoints"
    ManagedBy   = "Terraform"
  }
}

# Security Group for Bastion Host (Jump Server)
resource "aws_security_group" "bastion" {
  name_prefix = "${var.project_name}-bastion-"
  vpc_id      = aws_vpc.quakewatch_vpc.id
  description = "Security group for bastion host"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
    description = "SSH access from allowed IPs"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-bastion-sg"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "Bastion"
    ManagedBy   = "Terraform"
  }
}

# Security Group for k3s Master Nodes
resource "aws_security_group" "k3s_master" {
  name_prefix = "${var.project_name}-k3s-master-"
  vpc_id      = aws_vpc.quakewatch_vpc.id
  description = "Security group for k3s master nodes"

  # SSH access from bastion
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    description     = "SSH from bastion"
  }

  # k3s API server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "k3s API server"
  }

  # k3s node communication
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "etcd client and peer communication"
  }

  # k3s node communication
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "kubelet API"
  }

  # k3s node communication
  ingress {
    from_port   = 10251
    to_port     = 10251
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "kube-scheduler"
  }

  # k3s node communication
  ingress {
    from_port   = 10252
    to_port     = 10252
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "kube-controller-manager"
  }

  # k3s node communication
  ingress {
    from_port   = 10255
    to_port     = 10255
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "kubelet read-only API"
  }

  # k3s node communication
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "NodePort services"
  }

  # k3s node communication
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "NodePort services UDP"
  }

  # Flannel VXLAN
  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "Flannel VXLAN"
  }

  # k3s node communication
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "All traffic from self"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-k3s-master-sg"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "k3s Master"
    ManagedBy   = "Terraform"
  }
}

# Security Group for k3s Worker Nodes
resource "aws_security_group" "k3s_worker" {
  name_prefix = "${var.project_name}-k3s-worker-"
  vpc_id      = aws_vpc.quakewatch_vpc.id
  description = "Security group for k3s worker nodes"

  # SSH access from bastion
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    description     = "SSH from bastion"
  }

  # k3s node communication
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "kubelet API"
  }

  # k3s node communication
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "NodePort services"
  }

  # k3s node communication
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "NodePort services UDP"
  }

  # Flannel VXLAN
  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "Flannel VXLAN"
  }

  # k3s node communication
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "All traffic from self"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-k3s-worker-sg"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "k3s Worker"
    ManagedBy   = "Terraform"
  }
}

# Security Group for Application Load Balancer
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  vpc_id      = aws_vpc.quakewatch_vpc.id
  description = "Security group for Application Load Balancer"

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "ALB"
    ManagedBy   = "Terraform"
  }
}

# Security Group for RDS Database
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-"
  vpc_id      = aws_vpc.quakewatch_vpc.id
  description = "Security group for RDS database"

  # PostgreSQL access from k3s nodes
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.k3s_master.id, aws_security_group.k3s_worker.id]
    description     = "PostgreSQL from k3s nodes"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "RDS"
    ManagedBy   = "Terraform"
  }
}

# Security Group for ElastiCache Redis
resource "aws_security_group" "redis" {
  name_prefix = "${var.project_name}-redis-"
  vpc_id      = aws_vpc.quakewatch_vpc.id
  description = "Security group for ElastiCache Redis"

  # Redis access from k3s nodes
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.k3s_master.id, aws_security_group.k3s_worker.id]
    description     = "Redis from k3s nodes"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${var.project_name}-redis-sg"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "Redis"
    ManagedBy   = "Terraform"
  }
}
