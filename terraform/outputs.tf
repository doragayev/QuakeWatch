# Outputs for QuakeWatch k3s Cluster Infrastructure

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.quakewatch_vpc.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.quakewatch_vpc.cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.quakewatch_vpc.arn
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private_subnets[*].id
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = aws_subnet.database_subnets[*].id
}

# Internet Gateway Outputs
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.quakewatch_igw.id
}

# NAT Gateway Outputs
output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.nat_gateways[*].id
}

output "nat_gateway_public_ips" {
  description = "Public IPs of the NAT Gateways"
  value       = aws_eip.nat_eips[*].public_ip
}

# Security Group Outputs
output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

output "k3s_master_security_group_id" {
  description = "ID of the k3s master security group"
  value       = aws_security_group.k3s_master.id
}

output "k3s_worker_security_group_id" {
  description = "ID of the k3s worker security group"
  value       = aws_security_group.k3s_worker.id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

# EC2 Instance Outputs
output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = var.create_bastion ? aws_instance.bastion[0].public_ip : null
}

output "bastion_private_ip" {
  description = "Private IP of the bastion host"
  value       = var.create_bastion ? aws_instance.bastion[0].private_ip : null
}

output "k3s_master_private_ips" {
  description = "Private IPs of the k3s master nodes"
  value       = aws_instance.k3s_master[*].private_ip
}

output "k3s_worker_private_ips" {
  description = "Private IPs of the k3s worker nodes"
  value       = aws_instance.k3s_worker[*].private_ip
}

output "k3s_master_instance_ids" {
  description = "Instance IDs of the k3s master nodes"
  value       = aws_instance.k3s_master[*].id
}

output "k3s_worker_instance_ids" {
  description = "Instance IDs of the k3s worker nodes"
  value       = aws_instance.k3s_worker[*].id
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.k3s_alb.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.k3s_alb.zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.k3s_alb.arn
}

# Target Group Outputs
output "k3s_api_target_group_arn" {
  description = "ARN of the k3s API target group"
  value       = aws_lb_target_group.k3s_api.arn
}

output "quakewatch_app_target_group_arn" {
  description = "ARN of the QuakeWatch application target group"
  value       = aws_lb_target_group.quakewatch_app.arn
}

# S3 Bucket Outputs
output "k3s_backups_bucket_name" {
  description = "Name of the S3 bucket for k3s backups"
  value       = aws_s3_bucket.k3s_backups.bucket
}

output "k3s_backups_bucket_arn" {
  description = "ARN of the S3 bucket for k3s backups"
  value       = aws_s3_bucket.k3s_backups.arn
}

# IAM Role Outputs
output "k3s_master_role_arn" {
  description = "ARN of the k3s master IAM role"
  value       = aws_iam_role.k3s_master_role.arn
}

output "k3s_worker_role_arn" {
  description = "ARN of the k3s worker IAM role"
  value       = aws_iam_role.k3s_worker_role.arn
}

output "bastion_role_arn" {
  description = "ARN of the bastion IAM role"
  value       = aws_iam_role.bastion_role.arn
}

# Key Pair Outputs
output "key_pair_name" {
  description = "Name of the EC2 key pair"
  value       = aws_key_pair.quakewatch_key.key_name
}

# Connection Information
output "ssh_connection_info" {
  description = "SSH connection information"
  value = {
    bastion_public_ip = var.create_bastion ? aws_instance.bastion[0].public_ip : null
    ssh_command       = var.create_bastion ? "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.bastion[0].public_ip}" : "No bastion host created"
  }
}

output "k3s_connection_info" {
  description = "k3s connection information"
  value = {
    master_ips = aws_instance.k3s_master[*].private_ip
    worker_ips = aws_instance.k3s_worker[*].private_ip
    kubeconfig = "Copy kubeconfig from master node: /etc/rancher/k3s/k3s.yaml"
  }
}

output "application_access_info" {
  description = "Application access information"
  value = {
    alb_dns_name = aws_lb.k3s_alb.dns_name
    http_url     = "http://${aws_lb.k3s_alb.dns_name}"
    https_url    = var.ssl_certificate_arn != "" ? "https://${aws_lb.k3s_alb.dns_name}" : "HTTPS not configured"
  }
}

# Monitoring Information
output "monitoring_info" {
  description = "Monitoring and logging information"
  value = {
    s3_backup_bucket = aws_s3_bucket.k3s_backups.bucket
    cloudwatch_logs  = "Enable CloudWatch logs for detailed monitoring"
    prometheus_url   = "http://${aws_lb.k3s_alb.dns_name}:9090 (after Prometheus deployment)"
    grafana_url      = "http://${aws_lb.k3s_alb.dns_name}:3000 (after Grafana deployment)"
  }
}

# Cost Optimization Information
output "cost_optimization_info" {
  description = "Cost optimization recommendations"
  value = {
    instance_types = {
      master = var.k3s_master_instance_type
      worker = var.k3s_worker_instance_type
      bastion = var.bastion_instance_type
    }
    volume_sizes = {
      master_root = var.k3s_master_volume_size
      master_data = var.k3s_master_data_volume_size
      worker_root = var.k3s_worker_volume_size
      worker_data = var.k3s_worker_data_volume_size
    }
    recommendations = [
      "Consider using Spot instances for worker nodes in non-production environments",
      "Monitor ALB costs and consider using NLB for internal traffic",
      "Set up S3 lifecycle policies to reduce backup storage costs",
      "Use CloudWatch alarms to monitor costs"
    ]
  }
}
