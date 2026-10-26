variable "service_name" {
  type        = string
  description = "Base name for ECS resources"
}

variable "image" {
  type        = string
  description = "ECR image URI (with tag)"
}

variable "container_port" {
  type        = number
  description = "Port your app listens on"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets for FARGATE tasks"
}

variable "security_group_ids" {
  type        = list(string)
  description = "SGs for FARGATE tasks"
}

variable "execution_role_arn" {
  type        = string
  description = "ECS Task Execution Role ARN"
}

variable "task_role_arn" {
  type        = string
  description = "IAM Role ARN for app permissions"
}

variable "log_group_name" {
  type        = string
  description = "CloudWatch log group name"
}

variable "target_group_arn" {
  type        = string
  description = "ALB target group to register tasks into"
}

variable "min_capacity" {
  type        = number
  default     = 2
  description = "Minimum task count for auto scaling"
}

variable "max_capacity" {
  type        = number
  default     = 4
  description = "Maximum task count for auto scaling"
}

variable "cpu_target" {
  type        = number
  default     = 70
  description = "Average CPU utilization (%) the autoscaler tries to hold"
}

variable "scale_out_cooldown" {
  type        = number
  default     = 300
  description = "Seconds to wait after a scale-out before scaling out again"
}

variable "scale_in_cooldown" {
  type        = number
  default     = 300
  description = "Seconds to wait after a scale-in before scaling in again"
}

variable "ecs_count" {
  type        = number
  default     = 1
  description = "Desired Fargate task count"
}

variable "region" {
  type        = string
  description = "AWS region (for awslogs driver)"
}

variable "cpu_architecture" {
  type        = string
  default     = "ARM64"
  description = "Fargate CPU architecture: ARM64 or X86_64"
}

variable "cpu" {
  type        = string
  default     = "256"
  description = "vCPU units"
}

variable "memory" {
  type        = string
  default     = "512"
  description = "Memory (MiB)"
}
