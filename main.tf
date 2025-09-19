provider "aws" {
  region = var.aws_region
}

# VPC and Networking
module "vpc" {
  source = "./modules/vpc"
  
  environment    = var.environment
  vpc_cidr      = var.vpc_cidr
  public_cidrs  = var.public_cidrs
  private_cidrs = var.private_cidrs
}

# Security Groups
module "security_groups" {
  source = "./modules/security_groups"
  
  environment = var.environment
  vpc_id     = module.vpc.vpc_id
}

# ECS Cluster and Service
module "ecs" {
  source = "./modules/ecs"
  
  environment         = var.environment
  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  public_subnets     = module.vpc.public_subnets
  private_subnets    = module.vpc.private_subnets
  ecs_sg_id         = module.security_groups.ecs_sg_id
  alb_sg_id         = module.security_groups.alb_sg_id
  container_image    = var.container_image
  container_port     = var.container_port
  desired_count      = var.desired_count
  ssl_certificate_arn = var.ssl_certificate_arn
}

# Redis ElastiCache
module "elasticache" {
  source = "./modules/elasticache"
  
  environment            = var.environment
  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  private_subnets       = module.vpc.private_subnets
  redis_sg_id           = module.security_groups.redis_sg_id
  redis_node_type       = var.redis_node_type
  num_cache_nodes       = var.num_cache_nodes
  notification_topic_arns = var.notification_topic_arns
  common_tags           = var.common_tags
}