resource "aws_sns_topic" "this" {
  name                      = var.topic_name
  kms_master_key_id         = var.kms_key_arn
  application_success_feedback_role_arn = var.success_feedback_role_arn
  tags                      = var.tags
}

resource "aws_sns_topic_subscription" "this" {
  for_each  = var.subscriptions
  topic_arn = aws_sns_topic.this.arn
  protocol  = each.value.protocol
  endpoint  = each.value.endpoint
  depends_on = [
    aws_sns_topic.this
  ]
}