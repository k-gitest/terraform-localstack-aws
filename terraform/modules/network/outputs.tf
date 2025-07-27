output "vpc_id" {
  description = "作成されたVPCのID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "作成されたパブリックサブネットのIDリスト"
  value       = aws_subnet.public[*].id
}

/*
output "private_subnet_ids" {
  description = "作成されたプライベートサブネットのIDリスト"
  value       = aws_subnet.private[*].id
}
*/

output "ecs_fargate_security_group_id" {
  description = "ECS Fargateサービス用のセキュリティグループID"
  value       = aws_security_group.ecs_fargate_sg.id
}