output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.app.name
}

output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.app.name
}
