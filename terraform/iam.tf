# IAM Roles and Policies for QuakeWatch k3s Cluster
# This file defines IAM roles, policies, and instance profiles

# IAM Role for k3s Master Nodes
resource "aws_iam_role" "k3s_master_role" {
  name = "${var.project_name}-k3s-master-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-k3s-master-role"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "k3s Master"
    ManagedBy   = "Terraform"
  }
}

# IAM Role for k3s Worker Nodes
resource "aws_iam_role" "k3s_worker_role" {
  name = "${var.project_name}-k3s-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-k3s-worker-role"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "k3s Worker"
    ManagedBy   = "Terraform"
  }
}

# IAM Role for Bastion Host
resource "aws_iam_role" "bastion_role" {
  name = "${var.project_name}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-bastion-role"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "Bastion"
    ManagedBy   = "Terraform"
  }
}

# IAM Policy for k3s Master Nodes
resource "aws_iam_policy" "k3s_master_policy" {
  name        = "${var.project_name}-k3s-master-policy"
  description = "IAM policy for k3s master nodes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:DescribeImages",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeAvailabilityZones",
          "ec2:CreateTags",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeVolumeAttribute",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeVolumeModifications"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-*",
          "arn:aws:s3:::${var.project_name}-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:GetChange",
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-k3s-master-policy"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "k3s Master"
    ManagedBy   = "Terraform"
  }
}

# IAM Policy for k3s Worker Nodes
resource "aws_iam_policy" "k3s_worker_policy" {
  name        = "${var.project_name}-k3s-worker-policy"
  description = "IAM policy for k3s worker nodes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:DescribeImages",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeAvailabilityZones",
          "ec2:CreateTags",
          "ec2:AttachVolume",
          "ec2:DetachVolume"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-*",
          "arn:aws:s3:::${var.project_name}-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-k3s-worker-policy"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "k3s Worker"
    ManagedBy   = "Terraform"
  }
}

# IAM Policy for Bastion Host
resource "aws_iam_policy" "bastion_policy" {
  name        = "${var.project_name}-bastion-policy"
  description = "IAM policy for bastion host"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeTags",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeAvailabilityZones"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:StartSession",
          "ssm:TerminateSession",
          "ssm:ResumeSession",
          "ssm:DescribeSessions",
          "ssm:GetConnectionStatus"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-bastion-policy"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "Bastion"
    ManagedBy   = "Terraform"
  }
}

# Attach policies to roles
resource "aws_iam_role_policy_attachment" "k3s_master_policy_attachment" {
  role       = aws_iam_role.k3s_master_role.name
  policy_arn = aws_iam_policy.k3s_master_policy.arn
}

resource "aws_iam_role_policy_attachment" "k3s_worker_policy_attachment" {
  role       = aws_iam_role.k3s_worker_role.name
  policy_arn = aws_iam_policy.k3s_worker_policy.arn
}

resource "aws_iam_role_policy_attachment" "bastion_policy_attachment" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = aws_iam_policy.bastion_policy.arn
}

# Attach AWS managed policies
resource "aws_iam_role_policy_attachment" "k3s_master_ssm_attachment" {
  role       = aws_iam_role.k3s_master_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "k3s_worker_ssm_attachment" {
  role       = aws_iam_role.k3s_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "bastion_ssm_attachment" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profiles
resource "aws_iam_instance_profile" "k3s_master_profile" {
  name = "${var.project_name}-k3s-master-profile"
  role = aws_iam_role.k3s_master_role.name

  tags = {
    Name        = "${var.project_name}-k3s-master-profile"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "k3s Master"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_instance_profile" "k3s_worker_profile" {
  name = "${var.project_name}-k3s-worker-profile"
  role = aws_iam_role.k3s_worker_role.name

  tags = {
    Name        = "${var.project_name}-k3s-worker-profile"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "k3s Worker"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${var.project_name}-bastion-profile"
  role = aws_iam_role.bastion_role.name

  tags = {
    Name        = "${var.project_name}-bastion-profile"
    Environment = var.environment
    Project     = "QuakeWatch"
    Type        = "Bastion"
    ManagedBy   = "Terraform"
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Data source for current AWS region
data "aws_region" "current" {}
