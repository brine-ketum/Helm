# Gateway Load Balancer for vPacketStack
resource "aws_lb" "gwlb" {
  name               = var.gwlb_name
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.instance_sg.id]
  subnets            = [aws_subnet.traffic_subnet.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.gwlb_name}-${var.env}"
    Env  = var.env
  }
}

# Health Check (Probe) for Gateway Load Balancer
resource "aws_lb_target_group" "gwlb_health_check" {
  name        = var.gwlb_probe_name
  port        = var.gwlb_probe_port
  protocol    = "TCP"  # Use TCP instead of HTTP
  vpc_id      = aws_vpc.main_vpc.id

  health_check {
    healthy_threshold   = var.gwlb_probe_count
    interval            = var.gwlb_probe_interval
    timeout             = 5
    unhealthy_threshold = 2
    matcher             = "200"  # Update this according to your requirements
  }

  tags = {
    Name = "${var.gwlb_probe_name}-${var.env}"
    Env  = var.env
  }
}

# Load Balancer Listener for Gateway Load Balancer
resource "aws_lb_listener" "gwlb_listener" {
  load_balancer_arn = aws_lb.gwlb.arn
  port              = var.gwlb_rule_frontend_port
  protocol          = var.gwlb_rule_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gwlb_health_check.arn
  }

  tags = {
    Name = "${var.gwlb_lb_rule_name}-${var.env}"
    Env  = var.env
  }
}
