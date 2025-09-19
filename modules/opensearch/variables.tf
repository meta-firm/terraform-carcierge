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

variable "opensearch_sg_id" {
  description = "OpenSearch security group ID"
  type        = string
}

variable "opensearch_config" {
  description = "OpenSearch configuration"
  type = object({
    engine_version    = string
    instance_type     = string
    instance_count    = number
    volume_type       = string
    volume_size       = number
    dedicated_master_enabled = bool
    master_instance_type = string
    master_instance_count = number
    zone_awareness_enabled = bool
    encrypt_at_rest = bool
    node_to_node_encryption = bool
  })
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}