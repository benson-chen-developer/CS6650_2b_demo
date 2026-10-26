variable "service_name" {
  type        = string
  description = "Base name for ALB resources"
}

variable "container_port" {
  type        = number
  description = "Port your app listens on (also the ALB listener port)"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets for the ALB (at least 2 AZs)"
}
