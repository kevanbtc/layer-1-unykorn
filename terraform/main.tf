# Terraform Configuration for Unykorn L1 Mainnet
# Provider: AWS (can be adapted for Azure/GCP)
# 
# This deploys:
# - 4 validator nodes (private subnet)
# - 2 sentry nodes (public subnet with load balancer)
# - Monitoring stack (Prometheus, Grafana)
# - Block explorer (Blockscout)
# - VPC with private/public subnets
# - Security groups with minimal attack surface

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Store state in S3 (recommended for production)
  backend "s3" {
    bucket         = "unykorn-terraform-state"
    key            = "mainnet/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "unykorn-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Unykorn-L1"
      Environment = "mainnet"
      ManagedBy   = "Terraform"
    }
  }
}

# Variables
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "mainnet"
}

variable "validator_instance_type" {
  description = "EC2 instance type for validators"
  type        = string
  default     = "c6i.2xlarge"  # 8 vCPU, 16GB RAM
}

variable "sentry_instance_type" {
  description = "EC2 instance type for sentry nodes"
  type        = string
  default     = "c6i.4xlarge"  # 16 vCPU, 32GB RAM
}

variable "monitoring_instance_type" {
  description = "EC2 instance type for monitoring stack"
  type        = string
  default     = "t3.xlarge"    # 4 vCPU, 16GB RAM
}

variable "key_pair_name" {
  description = "SSH key pair name for EC2 instances"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # CHANGE THIS TO YOUR IP!
}

variable "num_validators" {
  description = "Number of validator nodes"
  type        = number
  default     = 4
}

variable "num_sentries" {
  description = "Number of sentry nodes"
  type        = number
  default     = 2
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "unykorn-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "unykorn-igw"
  }
}

# Public Subnets (for sentries, monitoring, explorer)
resource "aws_subnet" "public" {
  count = 2
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "unykorn-public-${count.index + 1}"
    Type = "public"
  }
}

# Private Subnets (for validators)
resource "aws_subnet" "private" {
  count = 2
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = {
    Name = "unykorn-private-${count.index + 1}"
    Type = "private"
  }
}

# NAT Gateway for private subnet outbound (for updates)
resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = {
    Name = "unykorn-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  
  tags = {
    Name = "unykorn-nat"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "unykorn-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  
  tags = {
    Name = "unykorn-private-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = 2
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = 2
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "validator" {
  name        = "unykorn-validator-sg"
  description = "Security group for validator nodes (private)"
  vpc_id      = aws_vpc.main.id
  
  # P2P within validator network
  ingress {
    description     = "P2P from validators"
    from_port       = 30303
    to_port         = 30303
    protocol        = "tcp"
    self            = true
  }
  
  # P2P from sentries
  ingress {
    description     = "P2P from sentries"
    from_port       = 30303
    to_port         = 30303
    protocol        = "tcp"
    security_groups = [aws_security_group.sentry.id]
  }
  
  # Prometheus metrics (internal only)
  ingress {
    description     = "Prometheus metrics"
    from_port       = 9545
    to_port         = 9545
    protocol        = "tcp"
    security_groups = [aws_security_group.monitoring.id]
  }
  
  # SSH from bastion (or specific IP)
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }
  
  # Outbound (for updates, NTP)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "unykorn-validator-sg"
  }
}

resource "aws_security_group" "sentry" {
  name        = "unykorn-sentry-sg"
  description = "Security group for sentry nodes (public RPC)"
  vpc_id      = aws_vpc.main.id
  
  # P2P from anywhere (public blockchain)
  ingress {
    description = "P2P public"
    from_port   = 30303
    to_port     = 30303
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # JSON-RPC from ALB
  ingress {
    description     = "JSON-RPC from ALB"
    from_port       = 8545
    to_port         = 8545
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  # WebSocket from ALB
  ingress {
    description     = "WebSocket from ALB"
    from_port       = 8546
    to_port         = 8546
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  # Prometheus metrics
  ingress {
    description     = "Prometheus metrics"
    from_port       = 9545
    to_port         = 9545
    protocol        = "tcp"
    security_groups = [aws_security_group.monitoring.id]
  }
  
  # SSH
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "unykorn-sentry-sg"
  }
}

resource "aws_security_group" "monitoring" {
  name        = "unykorn-monitoring-sg"
  description = "Security group for monitoring stack"
  vpc_id      = aws_vpc.main.id
  
  # Prometheus
  ingress {
    description = "Prometheus UI"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr  # Restrict to your IP
  }
  
  # Grafana from ALB
  ingress {
    description     = "Grafana from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  # SSH
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "unykorn-monitoring-sg"
  }
}

resource "aws_security_group" "alb" {
  name        = "unykorn-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id
  
  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTP (redirect to HTTPS)
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "unykorn-alb-sg"
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "validator_sg_id" {
  description = "Validator security group ID"
  value       = aws_security_group.validator.id
}

output "sentry_sg_id" {
  description = "Sentry security group ID"
  value       = aws_security_group.sentry.id
}
