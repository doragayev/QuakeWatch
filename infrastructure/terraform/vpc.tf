# VPC Configuration for QuakeWatch k3s Cluster
# This file defines the VPC, subnets, and networking components

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

# VPC
resource "aws_vpc" "quakewatch_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    Project     = "QuakeWatch"
    ManagedBy  = "Terraform"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "quakewatch_igw" {
  vpc_id = aws_vpc.quakewatch_vpc.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
    Project     = "QuakeWatch"
    ManagedBy   = "Terraform"
  }
}

# Public Subnets
resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.quakewatch_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "Public"
    ManagedBy   = "Terraform"
  }
}

# Private Subnets
resource "aws_subnet" "private_subnets" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.quakewatch_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-private-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "Private"
    ManagedBy   = "Terraform"
  }
}

# Database Subnets
resource "aws_subnet" "database_subnets" {
  count = length(var.database_subnet_cidrs)

  vpc_id            = aws_vpc.quakewatch_vpc.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-database-subnet-${count.index + 1}"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "Database"
    ManagedBy   = "Terraform"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat_eips" {
  count = length(var.public_subnet_cidrs)

  domain = "vpc"
  depends_on = [aws_internet_gateway.quakewatch_igw]

  tags = {
    Name        = "${var.project_name}-nat-eip-${count.index + 1}"
    Environment = var.environment
    Project     = "QuakeWatch"
    ManagedBy   = "Terraform"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "nat_gateways" {
  count = length(var.public_subnet_cidrs)

  allocation_id = aws_eip.nat_eips[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id

  tags = {
    Name        = "${var.project_name}-nat-gateway-${count.index + 1}"
    Environment = var.environment
    Project     = "QuakeWatch"
    ManagedBy   = "Terraform"
  }

  depends_on = [aws_internet_gateway.quakewatch_igw]
}

# Route Table for Public Subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.quakewatch_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.quakewatch_igw.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "Public"
    ManagedBy   = "Terraform"
  }
}

# Route Table for Private Subnets
resource "aws_route_table" "private_rt" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.quakewatch_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateways[count.index].id
  }

  tags = {
    Name        = "${var.project_name}-private-rt-${count.index + 1}"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "Private"
    ManagedBy   = "Terraform"
  }
}

# Route Table for Database Subnets
resource "aws_route_table" "database_rt" {
  vpc_id = aws_vpc.quakewatch_vpc.id

  tags = {
    Name        = "${var.project_name}-database-rt"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "Database"
    ManagedBy   = "Terraform"
  }
}

# Route Table Associations for Public Subnets
resource "aws_route_table_association" "public_rta" {
  count = length(aws_subnet.public_subnets)

  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Route Table Associations for Private Subnets
resource "aws_route_table_association" "private_rta" {
  count = length(aws_subnet.private_subnets)

  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

# Route Table Associations for Database Subnets
resource "aws_route_table_association" "database_rta" {
  count = length(aws_subnet.database_subnets)

  subnet_id      = aws_subnet.database_subnets[count.index].id
  route_table_id = aws_route_table.database_rt.id
}

# VPC Endpoints for S3 (to reduce NAT Gateway costs)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.quakewatch_vpc.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  
  tags = {
    Name        = "${var.project_name}-s3-endpoint"
    Environment = var.environment
    Project     = "QuakeWatch"
    ManagedBy   = "Terraform"
  }
}

# VPC Endpoints for ECR (for container registry access)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.quakewatch_vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnets[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-ecr-dkr-endpoint"
    Environment = var.environment
    Project     = "QuakeWatch"
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.quakewatch_vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnets[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-ecr-api-endpoint"
    Environment = var.environment
    Project     = "QuakeWatch"
    ManagedBy   = "Terraform"
  }
}

# VPC Endpoint for ECS (if using ECS tasks)
resource "aws_vpc_endpoint" "ecs" {
  vpc_id              = aws_vpc.quakewatch_vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnets[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-ecs-endpoint"
    Environment = var.environment
    Project     = "QuakeWatch"
    ManagedBy   = "Terraform"
  }
}

# VPC Endpoint for ECS Agent
resource "aws_vpc_endpoint" "ecs_agent" {
  vpc_id              = aws_vpc.quakewatch_vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecs-agent"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnets[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-ecs-agent-endpoint"
    Environment = var.environment
    Project     = "QuakeWatch"
    ManagedBy   = "Terraform"
  }
}

# VPC Endpoint for ECS Telemetry
resource "aws_vpc_endpoint" "ecs_telemetry" {
  vpc_id              = aws_vpc.quakewatch_vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecs-telemetry"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnets[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-ecs-telemetry-endpoint"
    Environment = var.environment
    Project     = "QuakeWatch"
    ManagedBy   = "Terraform"
  }
}
