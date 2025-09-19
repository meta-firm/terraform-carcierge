output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.ecs.alb_dns_name
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_names" {
  description = "The names of the ECS services"
  value       = module.ecs.service_names
}

output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = module.rds.endpoint
  sensitive   = true
}

output "rds_database_name" {
  description = "The name of the RDS database"
  value       = module.rds.database_name
}

output "redis_endpoint" {
  description = "The endpoint of the Redis cluster"
  value       = module.elasticache.endpoint
}

output "opensearch_endpoint" {
  description = "The endpoint of the OpenSearch cluster"
  value       = module.opensearch.endpoint
}

output "opensearch_dashboard_endpoint" {
  description = "The dashboard endpoint of the OpenSearch cluster"
  value       = module.opensearch.dashboard_endpoint
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "The IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "The IDs of the private subnets"
  value       = module.vpc.private_subnets
}