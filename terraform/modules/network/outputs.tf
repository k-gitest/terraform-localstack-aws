output "vpc_id" {
  description = "作成されたVPCのID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "作成されたパブリックサブネットのIDリスト"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "作成されたプライベートサブネットのIDリスト"
  value       = aws_subnet.private[*].id
}

output "application_security_group_id" {
  description = "アプリケーションサービス用のセキュリティグループID"
  value       = aws_security_group.application_sg.id
}

output "database_security_group_id" {
  description = "データベースサービス用のセキュリティグループID"
  value       = aws_security_group.database_sg.id
}

output "db_subnet_group_name" {
  description = "データベースサブネットグループの名前"
  value       = aws_db_subnet_group.database_subnet_group.name
}

output "db_subnet_group_id" {
  description = "データベースサブネットグループのID"
  value       = aws_db_subnet_group.database_subnet_group.id
}

output "alb_security_group_id" {
  description = "The ID of the security group attached to the ALB."
  value       = aws_security_group.alb_sg.id
}