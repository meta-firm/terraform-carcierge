# Infrastructure Settings
aws_region    = "us-west-1"
environment   = "staging"
project_name  = "stg-carcierge-api"

# VPC Configuration
vpc_cidr      = "10.0.0.0/16"
public_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]

# Container Configuration
container_image = "yet to update"
container_port  = 3002
desired_count   = 3
task_cpu = 1024                    # 2 vCPU for the task
task_memory = 3072                 # 3GB memory for the task
container_cpu    = 0  # Increased to 2 vCPU
#container_memory = 0  # Increased to 4GB

# Redis Configuration
redis_node_type = "cache.t4g.micro"  # Upgraded for better performance
num_cache_nodes = 1

# EC2 Configuration (for ECS)
instance_type = "t3a.large"  # Upgraded to m6i.large for production

# Auto Scaling Configuration
min_capacity = 3
max_capacity = 12
cpu_threshold = 75
memory_threshold = 75

# Scale-out Parameters
scale_out_cooldown = 300
scale_in_cooldown = 300
target_cpu_utilization = 70
target_memory_utilization = 70

# SSL Configuration
ssl_certificate_arn = "yet to update"  # Replace with your certificate ARN

# Additional Tags
additional_tags = {
  Owner       = "DevOps"
  Environment = "staging"
  Terraform   = "true"
}