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

variable "public_subnets" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "ECS security group ID"
  type        = string
}

variable "alb_sg_id" {
  description = "ALB security group ID"
  type        = string
}

variable "container_image" {
  description = "Docker image for the container"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
}

variable "task_cpu" {
  description = "Number of CPU units for the task (1 vCPU = 1024 CPU units)"
  type        = number
  default     = 1024  # 2 vCPU
}

variable "task_memory" {
  description = "Amount of memory in MiB for the task"
  type        = number
  default     = 3072  # 4GB
}
variable "container_cpu" {
  description = "CPU units for the container"
  type        = number
  default     = 0
}

variable "container_memory" {
  description = "Memory for the container in MB"
  type        = number
  default     = 0
}

variable "desired_count" {
  description = "Desired number of containers"
  type        = number
  default     = 3
}

variable "health_check_path" {
  description = "Health check path for the default target group"
  type        = string
  default     = "/"
}

variable "container_environment" {
  description = "Environment variables for the container"
  type        = list(map(string))
  default     = []
}

variable "max_capacity" {
  description = "Maximum number of containers"
  type        = number
  default     = 12
}

variable "min_capacity" {
  description = "Minimum number of containers"
  type        = number
  default     = 3
}

variable "cpu_threshold" {
  description = "CPU threshold for scaling"
  type        = number
  default     = 75
}

variable "memory_threshold" {
  description = "Memory threshold for scaling"
  type        = number
  default     = 75
}

variable "instance_type" {
  description = "EC2 instance type for ECS container instances"
  type        = string
  default     = "t3a.large"
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for HTTPS"
  type        = string
}

variable "notification_topic_arns" {
  description = "List of SNS topic ARNs for CloudWatch alarms"
  type        = list(string)
  default     = []
}