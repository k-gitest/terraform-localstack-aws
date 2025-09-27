output "sqs_queue_arn" {
  description = "SQSキューのARN"
  value       = aws_sqs_queue.this.arn
}

output "sqs_queue_url" {
  description = "SQSキューのURL"
  value       = aws_sqs_queue.this.id
}