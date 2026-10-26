output "ecs_cluster_name" {
  description = "Name of the created ECS cluster"
  value       = module.ecs.cluster_name
}

output "alb_dns_name" {
  description = "ALB DNS name (use http://<this>:8081 as the Locust host)"
  value       = module.alb.dns_name
}

output "ecs_service_name" {
  description = "Name of the running ECS service"
  value       = module.ecs.service_name
}