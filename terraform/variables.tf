# Variables for QuakeWatch k3s Cluster Infrastructure

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "quakewatch"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.30.0/24", "10.0.40.0/24"]
}

# Security Configuration
variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_public_key" {
  description = "Public SSH key for EC2 instances"
  type        = string
  default     = ""
}

# k3s Configuration
variable "k3s_token" {
  description = "k3s cluster token"
  type        = string
  default     = "quakewatch-k3s-token-2025"
  sensitive   = true
}

variable "k3s_master_count" {
  description = "Number of k3s master nodes"
  type        = number
  default     = 1
}

variable "k3s_worker_count" {
  description = "Number of k3s worker nodes"
  type        = number
  default     = 2
}

variable "k3s_master_instance_type" {
  description = "Instance type for k3s master nodes"
  type        = string
  default     = "t3.medium"
}

variable "k3s_worker_instance_type" {
  description = "Instance type for k3s worker nodes"
  type        = string
  default     = "t3.large"
}

# Volume Configuration
variable "k3s_master_volume_size" {
  description = "Root volume size for k3s master nodes (GB)"
  type        = number
  default     = 50
}

variable "k3s_master_data_volume_size" {
  description = "Data volume size for k3s master nodes (GB)"
  type        = number
  default     = 100
}

variable "k3s_worker_volume_size" {
  description = "Root volume size for k3s worker nodes (GB)"
  type        = number
  default     = 50
}

variable "k3s_worker_data_volume_size" {
  description = "Data volume size for k3s worker nodes (GB)"
  type        = number
  default     = 200
}

# Bastion Configuration
variable "create_bastion" {
  description = "Whether to create bastion host"
  type        = bool
  default     = true
}

variable "bastion_instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3.micro"
}

variable "bastion_volume_size" {
  description = "Volume size for bastion host (GB)"
  type        = number
  default     = 20
}

# SSL Configuration
variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for ALB"
  type        = string
  default     = ""
}

# k3s Datastore Configuration (for HA)
variable "k3s_datastore_endpoint" {
  description = "External datastore endpoint for k3s HA"
  type        = string
  default     = ""
}

variable "k3s_datastore_cafile" {
  description = "CA file for external datastore"
  type        = string
  default     = ""
}

variable "k3s_datastore_certfile" {
  description = "Cert file for external datastore"
  type        = string
  default     = ""
}

variable "k3s_datastore_keyfile" {
  description = "Key file for external datastore"
  type        = string
  default     = ""
}

# Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "QuakeWatch"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}
