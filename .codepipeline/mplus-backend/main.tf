### Codepipleine deployment backend
### Provider definition
provider "aws" {
  region = var.region
}


### S3 bucket related resource definitions
resource "aws_s3_bucket" "cpdeploy_backend" {
  bucket        = var.s3bucket_name
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }

  tags = var.common_tags
}

resource "aws_s3_bucket_versioning" "cpdeploy_backend_versioning" {
  bucket = aws_s3_bucket.cpdeploy_backend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cpdeploy_backend_encryption" {
  bucket = aws_s3_bucket.cpdeploy_backend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_bucket_policy" "remote_state" {
  bucket = aws_s3_bucket.cpdeploy_backend.id

  policy = <<POLICY
{
    "Version": "2008-10-17",
    "Statement": [
        {
          "Sid": "DenyInsecureAccess",
          "Effect": "Deny",
          "Principal": "*",
          "Action": "s3:*",
          "Resource": [
            "${aws_s3_bucket.cpdeploy_backend.arn}",
            "${aws_s3_bucket.cpdeploy_backend.arn}/*"
          ],
          "Condition": {
            "Bool": {
              "aws:SecureTransport": "false"
            }
          }
        },
        {
          "Sid": "EnforceEncryption",
          "Effect": "Deny",
          "Principal": "*",
          "Action": "s3:PutObject",
          "Resource": [
            "${aws_s3_bucket.cpdeploy_backend.arn}/*"
          ],
          "Condition": {
            "StringNotEquals": {
              "s3:x-amz-server-side-encryption": "AES256"
            }
          }
        },
        {
          "Sid": "DenyUnencryptedObjectUploads",
          "Effect": "Deny",
          "Principal": "*",
          "Action": "s3:PutObject",
          "Resource": [
            "${aws_s3_bucket.cpdeploy_backend.arn}/*"
          ],
          "Condition": {
            "Null": {
              "s3:x-amz-server-side-encryption": "true"
            }
          }
        }
    ]
}
POLICY

}


resource "aws_s3_bucket_public_access_block" "s3Public_remote_state" {
  depends_on              = [aws_s3_bucket_policy.remote_state]
  bucket                  = aws_s3_bucket.cpdeploy_backend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

### Dynamodb table related resource definitons
resource "aws_dynamodb_table" "cpdeploy_locks" {
  name         = var.dynamodb_tbl_name
  billing_mode = var.billing_mode
  hash_key     = "LockID"
  tags         = var.common_tags

  attribute {
    name = "LockID"
    type = "S"
  }
}


resource "aws_iam_role" "iam_role" {
  count = var.ssm_role_enable ? 1 : 0
  name                = var.ssm_iam_role
  path                = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = "arn:aws:iam::827782494956:root"
        }
      },
    ]
  })
  ###assume_role_policy  = templatefile("${path.module}/iam/${var.ssm_trust_policy_file}", {})
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",]

  tags = var.common_tags
}

