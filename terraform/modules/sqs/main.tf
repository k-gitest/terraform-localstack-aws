resource "aws_sqs_queue" "this" {
  name                       = var.queue_name
  fifo_queue                 = var.is_fifo_queue
  content_based_deduplication = var.is_fifo_queue
  visibility_timeout_seconds = var.visibility_timeout_seconds
  kms_master_key_id          = var.kms_key_arn
  redrive_policy             = var.dead_letter_queue_arn != null ? jsonencode({
    deadLetterTargetArn = var.dead_letter_queue_arn
    maxReceiveCount     = var.max_receive_count
  }) : null
  tags                       = var.tags
}