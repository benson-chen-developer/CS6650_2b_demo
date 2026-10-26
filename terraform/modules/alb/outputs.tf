# target groups id basically and pased to ecs to register their tasks with it
output "target_group_arn" {
  description = "Target group the ECS service registers tasks into"
  value       = aws_lb_target_group.this.arn

  # ECS rejects a target group that no listener points at yet, so wait for the listener
  depends_on = [aws_lb_listener.this]
}

# returns alb's public ip addres
output "dns_name" {
  description = "ALB DNS name, use this as the Locust host"
  value       = aws_lb.this.dns_name
}
