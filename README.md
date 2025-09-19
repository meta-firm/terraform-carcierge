# Carcierge Multi-Environment Infrastructure with ECS, Redis, OpenSearch, and RDS

This Terraform project sets up a production-ready infrastructure on AWS for hosting the Carcierge application using ECS (Elastic Container Service) with Redis caching, OpenSearch for search and analytics, and RDS for database services. The infrastructure is designed with high availability, scalability, and security in mind, supporting multiple environments and services.

## Architecture Overview

The infrastructure consists of:

- **VPC** with public and private subnets across multiple availability zones
- **NAT Gateways** for private subnet internet access
- **ECS Fargate cluster** for container orchestration (supporting multiple services)
- **Application Load Balancer (ALB)** for traffic distribution
- **Redis ElastiCache** for caching
- **OpenSearch** for search and analytics
- **RDS** for relational database services
- **Auto-scaling capabilities** based on CPU and memory utilization
- **CloudWatch** for logging and monitoring
- **S3 and DynamoDB** for Terraform state management

## Project Structure

The Carcierge application consists of 5 sub-projects, each deployed as separate ECS services:
1. Service 1 (configurable via terraform.tfvars)
2. Service 2 (configurable via terraform.tfvars)
3. Service 3 (configurable via terraform.tfvars)
4. Service 4 (configurable via terraform.tfvars)
5. Service 5 (configurable via terraform.tfvars)

## Environment Management

This infrastructure supports 4 environments managed through GitLab branches:
- **staging** → main branch
- **qa** → qa branch  
- **uat** → uat branch
- **prod** → prod branch

## Prerequisites

- Terraform >= 1.2.9
- AWS CLI configured with appropriate credentials
- Docker images for your Carcierge services pushed to ECR
- S3 bucket and DynamoDB table for state management
- SSL certificates in AWS Certificate Manager
- GitLab CI/CD configured

## Module Structure

```
.
├── main.tf                 # Main infrastructure configuration
├── variables.tf            # Input variables
├── outputs.tf             # Output values
├── backend.tf            # Terraform backend configuration
├── version.tf            # Provider and version constraints
├── terraform.tfvars      # Environment-specific configuration
├── pipeline-scripts/     # GitLab CI/CD scripts
└── modules/
    ├── vpc/              # VPC and networking
    ├── ecs/              # ECS cluster and services
    ├── elasticache/      # Redis configuration
    ├── opensearch/       # OpenSearch configuration
    ├── rds/              # RDS database configuration
    └── security_groups/  # Security group definitions
```

## Naming Convention

All resources follow the naming pattern:
```
<environment>-carcierge-<resource>-<subresource>
```

Examples:
- `staging-carcierge-ecs-cluster`
- `prod-carcierge-vpc-public-subnet`
- `qa-carcierge-alb-main`

## Configuration

### Environment-Specific Configuration

All environment-specific settings are managed through `terraform.tfvars`. Key configurations include:

```hcl
# Environment and Project
environment = "staging"  # staging, qa, uat, prod
project_name = "carcierge"

# Services Configuration
services = {
  service1 = {
    container_image = "your-ecr-repo/service1:latest"
    container_port = 3001
    desired_count = 2
    cpu = 512
    memory = 1024
  }
  service2 = {
    container_image = "your-ecr-repo/service2:latest"
    container_port = 3002
    desired_count = 2
    cpu = 512
    memory = 1024
  }
  # ... additional services
}

# Database Configuration
rds_config = {
  engine = "postgres"
  engine_version = "14.9"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  database_name = "carcierge"
  username = "carcierge_user"
}

# OpenSearch Configuration
opensearch_config = {
  engine_version = "OpenSearch_2.3"
  instance_type = "t3.small.search"
  instance_count = 1
  volume_size = 20
}
```

## GitLab CI/CD Pipeline

The pipeline includes the following stages:

### 1. Validate Stage
- Runs `terraform init`, `terraform validate`, and `terraform fmt`
- Ensures code quality and syntax correctness

### 2. Plan Stage
- Generates terraform plan
- Creates artifacts for review
- Runs on all branches

### 3. Analyse Stage (Optional)
- **Security Scan**: Runs security analysis if `RUN_SECURITY_SCAN=TRUE`
- **Cost Analysis**: Runs cost estimation if `RUN_COST_SCAN=TRUE`

### 4. Apply Stage
- **Manual Trigger**: Requires manual approval
- Only runs on main branch
- Applies the planned changes

### Pipeline Variables

Configure these variables in GitLab CI/CD settings:

```yaml
variables:
  ENVIRONMENTS: "staging"  # Current environment
  MODULES: "app"
  APP_NAME: "carcierge"
  TYPE: "app"
  BACKEND_REGION: "us-west-1"
  RUN_SECURITY_SCAN: "FALSE"
  RUN_COST_SCAN: "FALSE"
  TF_LOG: ""  # Terraform logging level
```

## Deployment Process

### 1. Initial Setup

1. **Configure Backend**: Update `backend.tf` with your S3 bucket and DynamoDB table
2. **Update Variables**: Modify `terraform.tfvars` for your environment
3. **Set Secrets**: Configure sensitive variables in GitLab CI/CD variables

### 2. Branch-Based Deployment

1. **Create/Update** `terraform.tfvars` for your target environment
2. **Commit and Push** to the appropriate branch
3. **Pipeline Execution**:
   - Validate stage runs automatically
   - Plan stage generates execution plan
   - Review the plan in GitLab artifacts
   - **Manual Approval** required for apply stage
4. **Apply** the changes after manual approval

### 3. Multi-Environment Management

Each environment is managed through its respective branch:

```bash
# Staging deployment
git checkout main
# Update terraform.tfvars with staging config
git commit -m "Update staging configuration"
git push origin main

# QA deployment  
git checkout qa
# Update terraform.tfvars with qa config
git commit -m "Update qa configuration"
git push origin qa
```

## Security Features

- **VPC Isolation**: All resources deployed in private subnets where possible
- **Security Groups**: Restrictive ingress/egress rules
- **Encryption**: At-rest and in-transit encryption enabled
- **IAM Roles**: Least privilege access principles
- **Network ACLs**: Additional network-level security
- **Secrets Management**: Sensitive data stored in AWS Secrets Manager

## High Availability Features

- **Multi-AZ Deployment**: Resources distributed across availability zones
- **Auto Scaling**: ECS services scale based on CPU/memory metrics
- **Load Balancing**: Application Load Balancer distributes traffic
- **Database Failover**: RDS Multi-AZ for automatic failover
- **Backup Strategy**: Automated backups for RDS and OpenSearch

## Monitoring and Logging

- **CloudWatch Logs**: Centralized logging for all services
- **CloudWatch Metrics**: Custom and AWS metrics monitoring
- **CloudWatch Alarms**: Automated alerting for critical metrics
- **Container Insights**: Enhanced ECS monitoring
- **OpenSearch Dashboards**: Log analysis and visualization

## Required Updates

Before deployment, update the following in `terraform.tfvars`:

### 1. Container Images
```hcl
services = {
  service1 = {
    container_image = "123456789012.dkr.ecr.us-west-1.amazonaws.com/carcierge-service1:latest"
    # ... other config
  }
}
```

### 2. SSL Certificates
```hcl
ssl_certificate_arn = "arn:aws:acm:us-west-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
```

### 3. Database Credentials
```hcl
rds_config = {
  username = "your_db_username"
  # Password will be auto-generated and stored in Secrets Manager
}
```

### 4. Domain Configuration
```hcl
domain_name = "carcierge.yourdomain.com"
```

## Troubleshooting

### Common Issues

1. **State Lock Issues**
```bash
terraform force-unlock LOCK_ID
```

2. **ECR Authentication**
```bash
aws ecr get-login-password --region us-west-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-west-1.amazonaws.com
```

3. **Service Discovery Issues**
- Check security group rules
- Verify service mesh configuration
- Review CloudWatch logs

### Pipeline Debugging

1. **Enable Terraform Logging**
```yaml
TF_LOG: "DEBUG"
```

2. **Review Artifacts**
- Download `.tfplan` files from GitLab artifacts
- Use `terraform show` to inspect plans

## Cost Optimization

- **Right-sizing**: Regularly review and adjust instance sizes
- **Reserved Instances**: Use RIs for predictable workloads
- **Spot Instances**: Consider spot instances for non-critical services
- **Auto Scaling**: Implement proper scaling policies
- **Resource Cleanup**: Regular cleanup of unused resources

## Backup and Disaster Recovery

- **RDS Automated Backups**: 7-day retention by default
- **OpenSearch Snapshots**: Daily automated snapshots
- **Infrastructure as Code**: Complete infrastructure reproducibility
- **Multi-Region**: Consider multi-region deployment for critical workloads

## Contributing

1. Create feature branch from appropriate environment branch
2. Update `terraform.tfvars` as needed
3. Test changes in lower environments first
4. Create merge request with detailed description
5. Ensure pipeline passes all stages
6. Require manual approval for production changes

## Support

For issues and questions:
1. Check CloudWatch logs for application issues
2. Review Terraform state for infrastructure issues
3. Use GitLab issues for tracking problems
4. Follow the troubleshooting guide above

## License

MIT License