output "dynamodb-lock-table" {
  value       = aws_dynamodb_table.lock_table.name
  description = "DynamoDB table for Terraform execution locks"
}

output "s3-state-bucket" {
  value       = aws_s3_bucket.backend.id
  description = "S3 bucket for storing Terraform state"
}
