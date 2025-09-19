variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "RDS security group ID"
  type        = string
}

variable "rds_config" {
  description = "RDS configuration"
  type = object({
    engine              = string
    engine_version      = string
    instance_class      = string
    allocated_storage   = number
    max_allocated_storage = number
    database_name       = string
    username           = string
    backup_retention_period = number
    backup_window      = string
    maintenance_window = string
    multi_az          = bool
    storage_encrypted = bool
    deletion_protection = bool
  })
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}