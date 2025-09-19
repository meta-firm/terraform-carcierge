# ECS Website Infrastructure with Redis

This Terraform project sets up a production-ready infrastructure on AWS for hosting a website using ECS (Elastic Container Service) with Redis caching. The infrastructure is designed with high availability, scalability, and security in mind.

## Architecture Overview

The infrastructure consists of:

- VPC with public and private subnets across multiple availability zones
- NAT Gateways for private subnet internet access
- ECS Fargate cluster for container orchestration
- Application Load Balancer (ALB) for traffic distribution
- Redis ElastiCache for caching
- Auto-scaling capabilities based on CPU and memory utilization
- CloudWatch for logging and monitoring
- S3 and DynamoDB for Terraform state management

## Prerequisites

- Terraform >= 1.0.0
- AWS CLI configured with appropriate credentials
- Docker image for your website application
- S3 bucket and DynamoDB table for state management

## Module Structure

```
.
├── main.tf                 # Main infrastructure configuration
├── variables.tf            # Input variables
├── outputs.tf             # Output values
├── backend.tf            # Terraform backend configuration
├── version.tf            # Provider and version constraints
├── state-backend.tf      # State storage infrastructure
└── modules/
    ├── vpc/              # VPC and networking
    ├── ecs/              # ECS cluster and service
    ├── elasticache/      # Redis configuration
    └── security_groups/  # Security group definitions
```

## Initial Setup

### 1. Set up State Backend

First, deploy the state management infrastructure:

```bash
# Initialize Terraform
terraform init

# Create state backend infrastructure
terraform apply -target=aws_s3_bucket.terraform_state -target=aws_dynamodb_table.terraform_state_lock

# Update backend.tf with your bucket and table names
```

### 2. Configure Variables

Create a `terraform.tfvars` file with your configuration:

```hcl
# Infrastructure Settings
aws_region    = "us-west-2"
environment   = "dev"
project_name  = "website"

# VPC Configuration
vpc_cidr      = "10.0.0.0/16"
public_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]

# Container Configuration
container_image = "your-docker-image:latest"
container_port  = 80
desired_count   = 2
container_cpu    = 256
container_memory = 512

# Redis Configuration
redis_node_type = "cache.t3.micro"

# Instance Configuration (if using EC2 launch type)
instance_type = "t3.micro"
```

### 3. Backend Configuration

Update `backend.tf` with your state storage details:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-website"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock-website"
    encrypt        = true
  }
}
```

## Deployment

1. Initialize Terraform with the backend configuration:
   ```bash
   terraform init
   ```

2. Review the execution plan:
   ```bash
   terraform plan -var-file="terraform.tfvars"
   ```
3. Apply the configuration:
   ```bash
   terraform apply -var-file="terraform.tfvars"
   ```

4. To destroy the infrastructure:
   ```bash
   terraform destroy
   ```

## Infrastructure Components

### VPC and Networking
- VPC with custom CIDR block
- Public and private subnets in multiple AZs
- Internet Gateway for public subnets
- NAT Gateways for private subnet internet access
- Route tables for public and private subnets

### ECS Configuration
- Fargate launch type
- Auto-scaling based on CPU and memory
- Application Load Balancer
- CloudWatch logging
- Launch template configuration (for EC2 launch type)

### Redis ElastiCache
- Single-node Redis cluster
- Subnet group in private subnets
- Security group with ECS access

### Security Groups
- ALB security group (ports 80, 443)
- ECS security group (application port)
- Redis security group (port 6379)

## Auto Scaling

The ECS service automatically scales based on:
- CPU utilization (threshold: 75%)
- Memory utilization (threshold: 75%)
- Minimum capacity: 1 container
- Maximum capacity: 4 containers

## Security

- All resources are deployed in a VPC with proper network segmentation
- Security groups restrict access to required ports only
- ECS tasks run in private subnets
- ALB is the only public-facing component
- Redis is deployed in private subnets with restricted access
- NAT Gateways enable private subnet internet access

## Monitoring and Logging

- CloudWatch log groups for ECS tasks
- Container insights enabled for enhanced monitoring
- ALB access logs (optional)
- Redis performance metrics

## State Management

The Terraform state is stored in:
- S3 bucket with versioning enabled
- DynamoDB table for state locking
- Server-side encryption enabled

### State Backend Setup Commands

```bash
# Create S3 bucket
aws s3api create-bucket \
    --bucket terraform-state-website \
    --region us-west-2 \
    --create-bucket-configuration LocationConstraint=us-west-2

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket terraform-state-website \
    --versioning-configuration Status=Enabled

# Create DynamoDB table
aws dynamodb create-table \
    --table-name terraform-state-lock-website \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --region us-west-2
```

## Outputs

- `alb_dns_name`: DNS name of the load balancer
- `ecs_cluster_name`: Name of the ECS cluster
- `ecs_service_name`: Name of the ECS service
- `redis_endpoint`: Endpoint of the Redis cluster
- `vpc_id`: ID of the created VPC
- `public_subnets`: IDs of public subnets
- `private_subnets`: IDs of private subnets

## Environment Variables

The ECS task definition includes the following environment variables:
- `REDIS_HOST`: Redis endpoint (automatically updated)
- `REDIS_PORT`: Redis port (default: 6379)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Troubleshooting

### Common Issues

1. State Lock Issues
```bash
# Force unlock state
terraform force-unlock LOCK_ID
```

2. Backend Configuration
```bash
# Reconfigure backend
terraform init -reconfigure
```

3. Resource Dependencies
```bash
# Target specific resources
terraform apply -target=module.vpc
```

## License

MIT License