variable "bucket_name" {
  description = "Name of the S3 Bucket to be used as identifier"
  type        = string
  default     = ""
}

variable "force_destroy" {
  description = "A boolean that indicates all objects (including any locked objects) should be deleted from the bucket so that the bucket can be destroyed without error"
  type        = bool
  default     = "false"
}

variable "bucket_tags" {
  description = "Tags for bucket"
  type        = map(string)
  default     = {}
}

variable "block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for this bucket"
  type        = bool
  default     = "true"
}

variable "block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket"
  type        = bool
  default     = "true"
}

variable "ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for this bucket"
  type        = bool
  default     = "true"
}

variable "restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket"
  type        = bool
  default     = "true"
}

variable "dynamodb_name" {
  description = "Name of the dynamodb table name to be used as identifier"
  type        = string
  default     = ""
}

variable "billing_mode" {
  description = "Controls how you are charged for read and write throughput and how you manage capacity"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "dynamodb_tags" {
  description = "A map of tags to populate on the created table"
  type        = map(string)
  default     = {}
}

variable "iac_role_name" {
  description = "Name of the iac role name to be used to assume for terraform backend role"
  type        = string
  default     = ""
}

variable "target_account_id" {
  description = "Account ID of the target account"
  type        = string
  default     = ""
}

variable "account_id" {
  description = "Account ID of the current account"
  type        = string
  default     = ""
}

variable "tf_backend_role_name" {
  description = "Terraform backend role name"
  type        = string
  default     = ""
}

variable "tf_backend_role_tags" {
  description = "A map of tags to populate on the terraform backend role"
  type        = map(string)
  default     = {}
}

variable "tf_backend_role_policy_name" {
  description = "Terraform backend role policy name"
  type        = string
  default     = ""
}
