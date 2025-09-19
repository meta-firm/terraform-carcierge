variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "environment" {
  description = "Environment name (staging, qa, uat, prod)"
  type        = string
  validation {
    condition     = contains(["staging", "qa", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: staging, qa, uat, prod."
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "carcierge"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "services" {
  description = "Configuration for ECS services"
  type = map(object({
    container_image = string
    container_port  = number
    desired_count   = number
    cpu            = number
    memory         = number
    health_check_path = optional(string, "/")
    environment_variables = optional(map(string), {})
  }))
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for HTTPS"
  type        = string
}

variable "rds_config" {
  description = "RDS configuration"
  type = object({
    engine              = string
    engine_version      = string
    instance_class      = string
    allocated_storage   = number
    max_allocated_storage = optional(number, 100)
    database_name       = string
    username           = string
    backup_retention_period = optional(number, 7)
    backup_window      = optional(string, "03:00-04:00")
    maintenance_window = optional(string, "sun:04:00-sun:05:00")
    multi_az          = optional(bool, false)
    storage_encrypted = optional(bool, true)
    deletion_protection = optional(bool, false)
  })
}

variable "opensearch_config" {
  description = "OpenSearch configuration"
  type = object({
    engine_version    = string
    instance_type     = string
    instance_count    = number
    volume_type       = optional(string, "gp3")
    volume_size       = number
    dedicated_master_enabled = optional(bool, false)
    master_instance_type = optional(string, "")
    master_instance_count = optional(number, 0)
    zone_awareness_enabled = optional(bool, false)
    encrypt_at_rest = optional(bool, true)
    node_to_node_encryption = optional(bool, true)
  })
}

variable "redis_config" {
  description = "Redis configuration"
  type = object({
    node_type           = string
    num_cache_nodes     = number
    parameter_group_family = optional(string, "redis7")
    engine_version      = optional(string, "7.0")
    port               = optional(number, 6379)
    maintenance_window = optional(string, "sun:05:00-sun:06:00")
    snapshot_window    = optional(string, "00:00-01:00")
    snapshot_retention_limit = optional(number, 5)
    automatic_failover_enabled = optional(bool, false)
    multi_az_enabled   = optional(bool, false)
    at_rest_encryption_enabled = optional(bool, true)
    transit_encryption_enabled = optional(bool, true)
  })
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}