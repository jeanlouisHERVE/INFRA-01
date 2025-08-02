resource "aws_lb" "prometheus_alb" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_groups
  subnets            = var.subnets
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "prometheus_alb" {
  name        = "${var.name}-tg"
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

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
  load_balancer_arn = aws_lb.prometheus_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus_alb.arn
  }
}

resource "aws_lb_target_group_attachment" "prometheus_attachments" {
  count             = length(var.target_instance_ids)
  target_group_arn  = aws_lb_target_group.prometheus_alb.arn
  target_id         = var.target_instance_ids[count.index]
  port              = var.target_port
}


# resource "aws_lb_listener" "prometheus_https" {
#   load_balancer_arn = aws_lb.prometheus_alb.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = var.acm_certificate_arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.prometheus_alb.arn
#   }
# }