provider "aws" {
  region = var.aws_region
}

# VPC and Networking
module "vpc" {
  source = "./modules/vpc"
  
  environment = var.environment
  project_name = var.project_name
  vpc_cidr = var.vpc_cidr
  public_cidrs = var.public_cidrs
  private_cidrs = var.private_cidrs
  common_tags = var.common_tags
}

# Security Groups
module "security_groups" {
  source = "./modules/security_groups"
  
  environment = var.environment
  project_name = var.project_name
  vpc_id = module.vpc.vpc_id
  common_tags = var.common_tags
}

# RDS Database
module "rds" {
  source = "./modules/rds"
  
  environment = var.environment
  project_name = var.project_name
  vpc_id = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  rds_sg_id = module.security_groups.rds_sg_id
  rds_config = var.rds_config
  common_tags = var.common_tags
}

# OpenSearch
module "opensearch" {
  source = "./modules/opensearch"
  
  environment = var.environment
  project_name = var.project_name
  vpc_id = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  opensearch_sg_id = module.security_groups.opensearch_sg_id
  opensearch_config = var.opensearch_config
  common_tags = var.common_tags
}

# ECS Cluster and Services
module "ecs" {
  source = "./modules/ecs"
  
  environment = var.environment
  project_name = var.project_name
  vpc_id = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets
  ecs_sg_id = module.security_groups.ecs_sg_id
  alb_sg_id = module.security_groups.alb_sg_id
  services = var.services
  ssl_certificate_arn = var.ssl_certificate_arn
  rds_endpoint = module.rds.endpoint
  redis_endpoint = module.elasticache.endpoint
  opensearch_endpoint = module.opensearch.endpoint
  common_tags = var.common_tags
}

# Redis ElastiCache
module "elasticache" {
  source = "./modules/elasticache"
  
  environment = var.environment
  project_name = var.project_name
  vpc_id = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  redis_sg_id = module.security_groups.redis_sg_id
  redis_config = var.redis_config
  common_tags = var.common_tags
}