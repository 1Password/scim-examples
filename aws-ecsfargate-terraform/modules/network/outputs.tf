output "vpc_id" {
  value       = data.aws_vpc.this.id
  description = "The ID of the selected or created AWS VPC."
}

output "public_subnets" {
  value       = data.aws_subnets.public.ids
  description = "A list of IDs for selected or created public subnets."
}

output "target_group_arn" {
  value       = aws_lb_target_group.op_scim_bridge.arn
  description = "The ARN of the target group for the load balancer."
}

output "lb_security_group_id" {
  value       = aws_security_group.lb.id
  description = "The ID of the security group for the load balancer."
}

output "lb_dns_name" {
  value       = aws_alb.app.dns_name
  description = "The ID of the security group for the load balancer."
}
