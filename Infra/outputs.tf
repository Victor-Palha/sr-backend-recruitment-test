output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "alb_dns_name" {
  description = "ALB DNS name (use as application URL)"
  value       = "http://${module.alb.dns_name}"
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.endpoint
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "s3_state_bucket" {
  description = "S3 bucket for Terraform state"
  value       = module.s3.bucket_name
}
