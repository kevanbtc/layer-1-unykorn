# EC2 Instances for Unykorn L1

# Validator Nodes (Private Subnet)
resource "aws_instance" "validator" {
  count = var.num_validators
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.validator_instance_type
  key_name      = var.key_pair_name
  
  subnet_id              = aws_subnet.private[count.index % 2].id
  vpc_security_group_ids = [aws_security_group.validator.id]
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 500  # GB - adjust based on growth projections
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = false  # Preserve data
  }
  
  user_data = templatefile("${path.module}/scripts/validator-init.sh", {
    validator_index = count.index
    chain_id        = 7777
    environment     = var.environment
  })
  
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"  # IMDSv2 only
  }
  
  monitoring = true  # Enable detailed CloudWatch monitoring
  
  tags = {
    Name = "unykorn-validator-${count.index}"
    Role = "validator"
  }
}

# Sentry Nodes (Public Subnet)
resource "aws_instance" "sentry" {
  count = var.num_sentries
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.sentry_instance_type
  key_name      = var.key_pair_name
  
  subnet_id              = aws_subnet.public[count.index % 2].id
  vpc_security_group_ids = [aws_security_group.sentry.id]
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 1000  # Larger for RPC node
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = false
  }
  
  user_data = templatefile("${path.module}/scripts/sentry-init.sh", {
    sentry_index = count.index
    chain_id     = 7777
    environment  = var.environment
  })
  
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  
  monitoring = true
  
  tags = {
    Name = "unykorn-sentry-${count.index}"
    Role = "sentry"
  }
}

# Monitoring Instance
resource "aws_instance" "monitoring" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.monitoring_instance_type
  key_name      = var.key_pair_name
  
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.monitoring.id]
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 200
    encrypted             = true
    delete_on_termination = false
  }
  
  user_data = templatefile("${path.module}/scripts/monitoring-init.sh", {
    environment = var.environment
  })
  
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  
  monitoring = true
  
  tags = {
    Name = "unykorn-monitoring"
    Role = "monitoring"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "unykorn-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  
  enable_deletion_protection = true  # Prevent accidental deletion
  enable_http2               = true
  
  tags = {
    Name = "unykorn-alb"
  }
}

# Target Group for RPC
resource "aws_lb_target_group" "rpc" {
  name     = "unykorn-rpc-tg"
  port     = 8545
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200,400"  # 400 is normal for JSON-RPC without body
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }
  
  tags = {
    Name = "unykorn-rpc-tg"
  }
}

# Attach sentries to RPC target group
resource "aws_lb_target_group_attachment" "rpc" {
  count = var.num_sentries
  
  target_group_arn = aws_lb_target_group.rpc.arn
  target_id        = aws_instance.sentry[count.index].id
  port             = 8545
}

# HTTPS Listener (requires ACM certificate)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.acm_certificate_arn  # Create this in ACM first
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rpc.arn
  }
}

# HTTP Listener (redirect to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type = "redirect"
    
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Elastic IPs for validators (optional, for static peering)
resource "aws_eip" "validator" {
  count    = var.num_validators
  instance = aws_instance.validator[count.index].id
  domain   = "vpc"
  
  tags = {
    Name = "unykorn-validator-${count.index}-eip"
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "validators" {
  name              = "/unykorn/validators"
  retention_in_days = 30
  
  tags = {
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "sentries" {
  name              = "/unykorn/sentries"
  retention_in_days = 30
  
  tags = {
    Environment = var.environment
  }
}

# Outputs
output "validator_private_ips" {
  description = "Private IPs of validator nodes"
  value       = aws_instance.validator[*].private_ip
}

output "sentry_public_ips" {
  description = "Public IPs of sentry nodes"
  value       = aws_instance.sentry[*].public_ip
}

output "monitoring_public_ip" {
  description = "Public IP of monitoring instance"
  value       = aws_instance.monitoring.public_ip
}

output "alb_dns_name" {
  description = "DNS name of Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "rpc_endpoint" {
  description = "Public RPC endpoint (use your domain with Route53)"
  value       = "https://${aws_lb.main.dns_name}"
}
