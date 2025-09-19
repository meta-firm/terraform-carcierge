variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
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

variable "container_image" {
  description = "Docker image for the website container"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the website container"
  type        = number
  default     = 80
}

variable "desired_count" {
  description = "Desired number of website containers"
  type        = number
  default     = 2
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.micro"
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

variable "min_capacity" {
  description = "Minimum number of containers"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of containers"
  type        = number
  default     = 4
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

variable "scale_out_cooldown" {
  description = "Cooldown period after scaling out"
  type        = number
  default     = 300
}

variable "scale_in_cooldown" {
  description = "Cooldown period after scaling in"
  type        = number
  default     = 300
}

variable "target_cpu_utilization" {
  description = "Target CPU utilization percentage"
  type        = number
  default     = 70
}

variable "target_memory_utilization" {
  description = "Target memory utilization percentage"
  type        = number
  default     = 70
}

variable "instance_type" {
  description = "EC2 instance type for ECS container instances"
  type        = string
  default     = "t3a.large"
}


variable "additional_tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for HTTPS"
  type        = string
}

variable "num_cache_nodes" {
  description = "Number of cache nodes for Redis cluster"
  type        = number
  default     = 0
}

variable "notification_topic_arns" {
  description = "List of SNS topic ARNs for CloudWatch alarms"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}

}

