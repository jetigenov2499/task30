output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.ecs_asg.name
}

output "load_balancer_dns_name" {
  description = "DNS name of the Load Balancer"
  value       = aws_lb.ecs_alb.dns_name
}
