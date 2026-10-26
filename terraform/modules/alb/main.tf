# Fetch the default VPC
data "aws_vpc" "default" {
  default = true
}

# Security group for the ALB: lets the internet reach the listener port
resource "aws_security_group" "alb" {
  name        = "${var.service_name}-alb-sg"
  description = "Allow inbound on ${var.container_port} to the ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }
}

# The load balancer itself, spread across the default VPC subnets (needs 2+ AZs)
resource "aws_lb" "this" {
  name               = "${var.service_name}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids
}

# Target group: Fargate tasks register here by IP, and the ALB health checks /health
resource "aws_lb_target_group" "this" {
  name        = "${var.service_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip" # required for Fargate (awsvpc) tasks
  vpc_id      = data.aws_vpc.default.id

  health_check {
    path                = "/health"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200"
  }
}

# Listener: accepts traffic on the container port and forwards it to the target group
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.container_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
