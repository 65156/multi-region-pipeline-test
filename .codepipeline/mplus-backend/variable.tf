### DO NOT EDIT or REMOVE THIS FILE
### Variable definiton for S3 bucket and Dynamodb table creation
variable "region" {}

variable "s3bucket_name" {}

variable "dynamodb_tbl_name" {}

variable "billing_mode" { default = "PAY_PER_REQUEST" }

variable "common_tags" {
  type    = map(string)
  default = { "purpose" = "backend", "environment" = "network-us-east-2", "customer" = "isp", "architecture" = "standard", "orchestrator" = "tekton-pipeline", "built_by" = "terraform", "compliance" = "none"}
}

variable "ssm_role_enable" {
  type    = bool
}

variable "ssm_iam_role" { default = "ssm-read-role" }

