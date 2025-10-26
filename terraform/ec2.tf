# EC2 Instances for QuakeWatch k3s Cluster
# This file defines EC2 instances for k3s master and worker nodes

# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Data source for latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Key Pair for SSH access
resource "aws_key_pair" "quakewatch_key" {
  key_name   = "${var.project_name}-key"
  public_key = var.ssh_public_key

  tags = {
    Name        = "${var.project_name}-key"
    Environment = var.environment
    Project     = "QuakeWatch"
    ManagedBy   = "Terraform"
  }
}

# Bastion Host (Jump Server)
resource "aws_instance" "bastion" {
  count = var.create_bastion ? 1 : 0

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.bastion_instance_type
  key_name              = aws_key_pair.quakewatch_key.key_name
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = aws_subnet.public_subnets[0].id
  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name

  user_data = base64encode(templatefile("${path.module}/scripts/bastion-userdata.sh", {
    project_name = var.project_name
    environment  = var.environment
  }))

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.bastion_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name        = "${var.project_name}-bastion-root"
      Environment = var.environment
      Project     = "QuakeWatch"
      ManagedBy   = "Terraform"
    }
  }

  tags = {
    Name        = "${var.project_name}-bastion"
    Environment = var.environment
    Project     = "QuakeWatch"
    Role        = "Bastion"
    ManagedBy   = "Terraform"
  }
}

# k3s Master Nodes
resource "aws_instance" "k3s_master" {
  count = var.k3s_master_count

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.k3s_master_instance_type
  key_name              = aws_key_pair.quakewatch_key.key_name
  vpc_security_group_ids = [aws_security_group.k3s_master.id]
  subnet_id              = aws_subnet.private_subnets[count.index % length(aws_subnet.private_subnets)].id
  iam_instance_profile   = aws_iam_instance_profile.k3s_master_profile.name

  user_data = base64encode(templatefile("${path.module}/scripts/k3s-master-userdata.sh", {
    project_name     = var.project_name
    environment      = var.environment
    k3s_token        = var.k3s_token
    master_count     = var.k3s_master_count
    node_index       = count.index
    is_first_master  = count.index == 0
    datastore_endpoint = var.k3s_datastore_endpoint
    datastore_cafile = var.k3s_datastore_cafile
    datastore_certfile = var.k3s_datastore_certfile
    datastore_keyfile = var.k3s_datastore_keyfile
  }))

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.k3s_master_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name        = "${var.project_name}-k3s-master-${count.index + 1}-root"
      Environment = var.environment
      Project     = "QuakeWatch"
      ManagedBy   = "Terraform"
    }
  }

  # Additional EBS volume for k3s data
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp3"
    volume_size = var.k3s_master_data_volume_size
    encrypted   = true

    tags = {
      Name        = "${var.project_name}-k3s-master-${count.index + 1}-data"
      Environment = var.environment
      Project     = "QuakeWatch"
      ManagedBy   = "Terraform"
    }
  }

  tags = {
    Name        = "${var.project_name}-k3s-master-${count.index + 1}"
    Environment = var.environment
    Project     = "QuakeWatch"
    Role        = "k3s-master"
    NodeIndex   = count.index
    ManagedBy   = "Terraform"
  }
}

# k3s Worker Nodes
resource "aws_instance" "k3s_worker" {
  count = var.k3s_worker_count

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.k3s_worker_instance_type
  key_name              = aws_key_pair.quakewatch_key.key_name
  vpc_security_group_ids = [aws_security_group.k3s_worker.id]
  subnet_id              = aws_subnet.private_subnets[count.index % length(aws_subnet.private_subnets)].id
  iam_instance_profile   = aws_iam_instance_profile.k3s_worker_profile.name

  user_data = base64encode(templatefile("${path.module}/scripts/k3s-worker-userdata.sh", {
    project_name = var.project_name
    environment  = var.environment
    k3s_token    = var.k3s_token
    k3s_server  = aws_instance.k3s_master[0].private_ip
    node_index  = count.index
  }))

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.k3s_worker_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name        = "${var.project_name}-k3s-worker-${count.index + 1}-root"
      Environment = var.environment
      Project     = "QuakeWatch"
      ManagedBy   = "Terraform"
    }
  }

  # Additional EBS volume for container data
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp3"
    volume_size = var.k3s_worker_data_volume_size
    encrypted   = true

    tags = {
      Name        = "${var.project_name}-k3s-worker-${count.index + 1}-data"
      Environment = var.environment
      Project     = "QuakeWatch"
      ManagedBy   = "Terraform"
    }
  }

  tags = {
    Name        = "${var.project_name}-k3s-worker-${count.index + 1}"
    Environment = var.environment
    Project     = "QuakeWatch"
    Role        = "k3s-worker"
    NodeIndex   = count.index
    ManagedBy   = "Terraform"
  }
}

# Application Load Balancer for k3s API server
resource "aws_lb" "k3s_alb" {
  name               = "${var.project_name}-k3s-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public_subnets[*].id

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-k3s-alb"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "ALB"
    ManagedBy   = "Terraform"
  }
}

# Target Group for k3s API server
resource "aws_lb_target_group" "k3s_api" {
  name     = "${var.project_name}-k3s-api-tg"
  port     = 6443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.quakewatch_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/healthz"
    port                = "traffic-port"
    protocol            = "HTTPS"
    matcher             = "200"
  }

  tags = {
    Name        = "${var.project_name}-k3s-api-tg"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "Target Group"
    ManagedBy   = "Terraform"
  }
}

# Target Group for QuakeWatch application
resource "aws_lb_target_group" "quakewatch_app" {
  name     = "${var.project_name}-quakewatch-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.quakewatch_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name        = "${var.project_name}-quakewatch-app-tg"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "Target Group"
    ManagedBy   = "Terraform"
  }
}

# Target Group Attachments for k3s API server
resource "aws_lb_target_group_attachment" "k3s_api" {
  count            = var.k3s_master_count
  target_group_arn = aws_lb_target_group.k3s_api.arn
  target_id        = aws_instance.k3s_master[count.index].id
  port             = 6443
}

# Target Group Attachments for QuakeWatch application
resource "aws_lb_target_group_attachment" "quakewatch_app" {
  count            = var.k3s_worker_count
  target_group_arn = aws_lb_target_group.quakewatch_app.arn
  target_id        = aws_instance.k3s_worker[count.index].id
  port             = 30000
}

# ALB Listener for k3s API server
resource "aws_lb_listener" "k3s_api" {
  load_balancer_arn = aws_lb.k3s_alb.arn
  port              = "6443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k3s_api.arn
  }
}

# ALB Listener for QuakeWatch application
resource "aws_lb_listener" "quakewatch_app" {
  load_balancer_arn = aws_lb.k3s_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.quakewatch_app.arn
  }
}

# ALB Listener for HTTPS QuakeWatch application
resource "aws_lb_listener" "quakewatch_app_https" {
  count             = var.ssl_certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.k3s_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.quakewatch_app.arn
  }
}

# S3 Bucket for k3s backups
resource "aws_s3_bucket" "k3s_backups" {
  bucket = "${var.project_name}-k3s-backups-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "${var.project_name}-k3s-backups"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "Backups"
    ManagedBy   = "Terraform"
  }
}

# Random string for S3 bucket suffix
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket versioning
resource "aws_s3_bucket_versioning" "k3s_backups" {
  bucket = aws_s3_bucket.k3s_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "k3s_backups" {
  bucket = aws_s3_bucket.k3s_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "k3s_backups" {
  bucket = aws_s3_bucket.k3s_backups.id

  rule {
    id     = "backup_lifecycle"
    status = "Enabled"

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}
