provider "aws" {
  region = var.aws_region
}

resource "aws_autoscaling_group" "ecs_asg" {
  name                      = "ecs-asg"
  min_size                  = 1
  max_size                  = 10
  desired_capacity          = 1
  health_check_grace_period = 300
  launch_configuration      = aws_launch_configuration.ecs_launch_config.name

  vpc_zone_identifier = var.subnets

  tag {
    key                 = "Name"
    value               = "ecs-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "ecs_launch_config" {
  name_prefix          = "ecs-launch-config"
  image_id             = var.ecs_ami_id
  instance_type        = var.instance_type
  security_groups      = var.security_groups
  iam_instance_profile = var.iam_instance_profile
  key_name             = var.key_pair_name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_out_alarm" {
  alarm_name          = "ecs-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "CPU utilization goes over 70%"
  alarm_actions       = [aws_autoscaling_policy.scale_out_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ecs_asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_in_alarm" {
  alarm_name          = "ecs-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30
  alarm_description   = "CPU utilization goes below 30%"
  alarm_actions       = [aws_autoscaling_policy.scale_in_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ecs_asg.name
  }
}

resource "aws_autoscaling_policy" "scale_out_policy" {
  name               = "scale-out-policy"
  autoscaling_group_name = aws_autoscaling_group.ecs_asg.name
  policy_type        = "SimpleScaling"
  adjustment_type    = "ChangeInCapacity"
  scaling_adjustment = 1
}

resource "aws_autoscaling_policy" "scale_in_policy" {
  name               = "scale-in-policy"
  autoscaling_group_name = aws_autoscaling_group.ecs_asg.name
  policy_type        = "SimpleScaling"
  adjustment_type    = "ChangeInCapacity"
  scaling_adjustment = -1
}

resource "aws_lb" "ecs_alb" {
  name                  = "ecs-alb"
  internal              = false
  load_balancer_type    = "application"
  security_groups       = var.security_groups
  subnets               = var.subnets

  enable_deletion_protection = false

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "ecs_target_group" {
  name        = "ecs-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200-299"
  }
}

resource "aws_lb_listener" "ecs_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "ecs_target_group_attachment" {
  target_group_arn = aws_lb_target_group.ecs_target_group.arn
  target_id        = "i-0b5aafcf2666be6ec" 
  port             = 80
}
