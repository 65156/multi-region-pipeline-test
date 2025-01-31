resource "aws_dynamodb_table" "lock_table" {
  name         = var.dynamodb_name
  billing_mode = var.billing_mode
  hash_key     = "LockID"
  tags         = var.dynamodb_tags

  attribute {
    name = "LockID"
    type = "S"
  }
}
