resource "aws_iam_role" "tf_backend_role" {
  description = "Terraform backend Role"
  name        = var.tf_backend_role_name
  tags        = var.tf_backend_role_tags
  assume_role_policy = templatefile("${path.module}/iam/trust-policies/tf_backend_role.tpl", {
    account_id        = var.account_id
    target_account_id = var.target_account_id
    iac_role_name     = var.iac_role_name
  })
}

resource "aws_iam_role_policy" "tf_backend_role_policy" {
  name = var.tf_backend_role_policy_name
  role = aws_iam_role.tf_backend_role.id

  policy = templatefile("${path.module}/iam/role-policies/tf_backend_role_policy.tpl", {
    bucket-arn        = aws_s3_bucket.backend.arn
    dynamodb-arn      = aws_dynamodb_table.lock_table.arn
    target_account_id = var.target_account_id
    iac_role_name     = var.iac_role_name
  })
}
