### DO NOT EDIT or REMOVE THIS FILE
output "dynamodb-table" {
  value       = aws_dynamodb_table.cpdeploy_locks.name
}

output "s3-tfstate-bucket" {
  value       = aws_s3_bucket.cpdeploy_backend.id
}
