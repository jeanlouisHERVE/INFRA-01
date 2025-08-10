resource "aws_lb" "prometheus_alb" {
  count = length(var.target_instance_ids) > 0 ? 1 : 0

  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.subnets
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "prometheus_alb" {
  count       = length(var.target_instance_ids) > 0 ? 1 : 0
  name        = "${var.name}-tg"
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "prometheus_alb" {
  count = length(var.target_instance_ids) > 0 ? 1 : 0

  load_balancer_arn = aws_lb.prometheus_alb[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus_alb[0].arn
  }
}

resource "aws_lb_target_group_attachment" "prometheus_attachments" {
  count             = length(var.target_instance_ids)
  target_group_arn  = aws_lb_target_group.prometheus_alb[0].arn
  target_id         = var.target_instance_ids[count.index]
  port              = var.target_port
}