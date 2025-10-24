variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for HTTPS (create in AWS Certificate Manager first)"
  type        = string
  default     = ""  # Set this after creating cert
}

variable "domain_name" {
  description = "Domain name for RPC endpoint (e.g., rpc.unykorn.com)"
  type        = string
  default     = ""
}

variable "enable_backups" {
  description = "Enable automated EBS snapshots"
  type        = bool
  default     = true
}

variable "snapshot_retention_days" {
  description = "Number of days to retain EBS snapshots"
  type        = number
  default     = 7
}

variable "enable_monitoring_alarms" {
  description = "Enable CloudWatch alarms for monitoring"
  type        = bool
  default     = true
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = ""
}
