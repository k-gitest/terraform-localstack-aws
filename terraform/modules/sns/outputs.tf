output "sns_topic_arn" {
  description = "SNSトピックのARN"
  value       = aws_sns_topic.this.arn
}

output "sns_topic_name" {
  description = "SNSトピックの名前"
  value       = aws_sns_topic.this.name
}