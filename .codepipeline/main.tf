data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

##### CODEPIPELINE #####
resource "aws_codepipeline" "infra_pipeline" {
  for_each = local.codepipeline_config
  name     = join("-", [local.prefix, local.environment, each.value.cp_name, local.region])
  role_arn = local.iam_roles[each.value.cp_service_role_name]
  tags     = lookup(each.value, "tags", {})

  artifact_store {
    location = local.s3_buckets[each.value.s3_bucket]
    type     = "S3"
  }

  stage {
      name = "source"
      dynamic "action" {
        for_each = { for s in local.cp_stage_source_actions : s.name => s }
        content {
          name             = action.value.name
          category         = action.value.category
          owner            = action.value.owner
          provider         = action.value.provider
          version          = action.value.version
          output_artifacts = lookup(action.value, "output_artifacts", [])
          input_artifacts  = lookup(action.value, "input_artifacts", [])
          namespace        = lookup(action.value, "namespace", [])
          run_order        = lookup(action.value, "run_order", [])

          configuration = {
            ConnectionArn        = try(data.aws_codestarconnections_connection.codestar[action.value.codestar_connection].id, "")
            FullRepositoryId     = lookup(action.value, "iac_repo_name", "")
            BranchName           = lookup(action.value, "iac_repo_branch_name", "")
            OutputArtifactFormat = lookup(action.value, "outputartifactformat", "")
            DetectChanges        = lookup(action.value, "detectchanges", "")
          }
        }
      }
  }

  stage {
      name = "tf_plan"
      dynamic "action" {
        for_each = { for s in local.cp_stage_plan_actions : s.name => s }
        content {
          name             = action.value.name
          category         = action.value.category
          owner            = action.value.owner
          provider         = action.value.provider
          version          = action.value.version
          output_artifacts = lookup(action.value, "output_artifacts", [])
          input_artifacts  = lookup(action.value, "input_artifacts", [])
          namespace        = lookup(action.value, "namespace", [])
          run_order        = lookup(action.value, "run_order", [])

          configuration = {
            ProjectName = try(aws_codebuild_project.infra_provision[tostring(action.value.projectname)].name, "")
          }
        }
      }
  }
  stage {
      name = "approval"
      dynamic "action" {
        for_each = { for s in local.cp_stage_approve_actions : s.name => s }
        content {
          name             = action.value.name
          category         = action.value.category
          owner            = action.value.owner
          provider         = action.value.provider
          version          = action.value.version
          output_artifacts = lookup(action.value, "output_artifacts", [])
          input_artifacts  = lookup(action.value, "input_artifacts", [])
          namespace        = lookup(action.value, "namespace", [])
          run_order        = lookup(action.value, "run_order", [])

          configuration = {
            ExternalEntityLink = "#{PLAN.review_link}"
            NotificationArn    = try(aws_sns_topic.codepipeline_sns_topic[action.value.sns_topic].arn, "")
            CustomData         = lookup(action.value, "customdata", "")
          }
        }
      }
  }
  stage {
      name = "tf_apply"
      dynamic "action" {
        for_each = { for s in local.cp_stage_apply_actions : s.name => s }
        content {
          name             = action.value.name
          category         = action.value.category
          owner            = action.value.owner
          provider         = action.value.provider
          version          = action.value.version
          output_artifacts = lookup(action.value, "output_artifacts", [])
          input_artifacts  = lookup(action.value, "input_artifacts", [])
          namespace        = lookup(action.value, "namespace", [])
          run_order        = lookup(action.value, "run_order", [])

          configuration = {
            ProjectName = try(aws_codebuild_project.infra_provision[action.value.projectname].name, "")
          }
        }
      }
  }
}



##### CODEPIPELINE ##### 
resource "aws_codebuild_project" "infra_provision" {
  depends_on    = [aws_cloudwatch_log_group.infra_provision_lg]
  for_each      = local.codebuild_config
  name          = join("-", [local.prefix, local.environment, each.value.cb_project_name, local.region])
  description   = join("-", [local.prefix, local.environment, each.value.description, local.region])
  build_timeout = tostring(each.value.codebuild_timeout)
  service_role  = aws_iam_role.role[each.value.cb_service_role_name].arn
  tags          = each.value.tags

  artifacts {
    type = each.value.artifacts_type
  }

  environment {
    compute_type                = each.value.compute_type
    image                       = each.value.image
    type                        = each.value.type
    image_pull_credentials_type = each.value.image_pull_credentials_type
    environment_variable {
      name  = "IAM_ROLE"
      value = local.pipeline_shared ? local.iac_role_name : join("-", [local.prefix, local.environment, each.value.iac_role_name, local.region])
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "ACCOUNT_ID"
      value = local.pipeline_shared ? local.target_account_id : data.aws_caller_identity.current.account_id
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "CB_PROJECT_NAME"
      value = join("-", [local.prefix, local.environment, each.value.cb_project_name, local.region])
      type  = "PLAINTEXT"
    }
    environment_variable {
      name  = "TF_S3_BUCKET"
      value = join("-", [local.prefix, local.environment, each.value.tf_backend_bucket_name, local.region])
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "TF_BACKEND_REGION"
      value = data.aws_region.current.name
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "TF_BACKEND_ENCRYPT"
      value = each.value.tf_backend_encrypt
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "TF_DDB_TABLE"
      value = join("-", [local.prefix, local.environment, each.value.tf_backend_dynamodb_name, local.region])
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "TF_S3_KEY"
      value = "${local.prefix}/${local.environment}/${each.value.tf_s3_key}"
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "SHARED_ACCOUNT_ID"
      value = each.value.shared_account
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "SHARED_IAM_ROLE"
      value = each.value.shared_account_role
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "TF_BACKEND_ROLE"
      value = join("-", [local.prefix, local.environment, each.value.tf_backend_role_name, local.region])
      type  = "PLAINTEXT"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.infra_provision_lg[each.value.cloudwatch_log_group].name
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.cp_artifact_bucket[each.value.s3_bucket].id}/infra-provision-logs"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspecs/${each.value.build_spec_file}")
  }

}

##### CODESTAR #####
data "aws_codestarconnections_connection" "codestar" {
  for_each = local.codestar_existing
  name     = each.value.codestar_connection_name
}

resource "aws_codestarconnections_connection" "githubenterprise" {
  for_each = local.codestar_config
  name     = join("-", [local.prefix, local.environment, each.value.codestar_connection_name, local.region])
  host_arn = aws_codestarconnections_host.githubenterprise[0].arn
  tags     = each.value.tags
}

resource "aws_codestarconnections_host" "githubenterprise" {
  for_each          = local.codestar_config
  name              = each.value.codestar_connection_host_name
  provider_endpoint = each.value.github_enterprise_url
  provider_type     = each.value.provider_type
}


##### IAM ######

resource "aws_iam_role" "role" {
  for_each    = local.iam_roles_config
  description = each.value.description
  name        = join("-", [local.prefix, local.environment, each.value.role_name, local.region])
  tags        = each.value.tags
  assume_role_policy = templatefile("${path.module}/iam/trust-policies/${each.value.assume_role_policy_file}", {
  account_id = data.aws_caller_identity.current.account_id })
}

resource "aws_iam_role_policy" "role_policy" {
  for_each = local.iam_policy_config
  name     = join("-", [local.prefix, local.environment, each.value.policy_name, local.region])
  role     = aws_iam_role.role[each.value.role_name].id
  policy = templatefile("${path.module}/iam/role-policies/${each.value.role_policy_file}", {
    cp_artifact_bucket_arn                      = aws_s3_bucket.cp_artifact_bucket[each.value.cp_artifact_bucket].arn
    data_aws_partition_current_partition        = data.aws_partition.current.partition
    data_aws_caller_identity_current_account_id = data.aws_caller_identity.current.account_id
    data_aws_region_current_name                = data.aws_region.current.name
    target_account_id                           = local.pipeline_shared ? local.target_account_id : data.aws_caller_identity.current.account_id
    shared_account_id                           = each.value.shared_account
    shared_account_role                         = each.value.shared_account_role
    iac_role_name                               = local.pipeline_shared ? local.iac_role_name : join("-", [local.prefix, local.environment, each.value.iac_role_name, local.region])
  })
}

##### S3 ARTIFACTS #####
resource "aws_s3_bucket" "cp_artifact_bucket" {
  for_each      = local.storage_config
  bucket        = join("-", [local.prefix, local.environment, each.value.name, local.region])
  force_destroy = each.value.force_destroy

  lifecycle {
    prevent_destroy = false
  }

  tags = each.value.tags
}

resource "aws_s3_bucket_versioning" "cp_artifact_bucket_versioning" {
  for_each = local.storage_config
  bucket   = aws_s3_bucket.cp_artifact_bucket[each.value.id].id

  versioning_configuration {
    status = each.value.versioning
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cp_artifact_bucket_encryption" {
  for_each = local.storage_config
  bucket   = aws_s3_bucket.cp_artifact_bucket[each.value.id].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = each.value.bucket_encryption_algorithm
    }
  }
}

resource "aws_s3_bucket_public_access_block" "s3_Public_cp_artifact" {
  for_each                = local.storage_config
  bucket                  = aws_s3_bucket.cp_artifact_bucket[each.value.id].id
  block_public_acls       = each.value.block_public_acls
  block_public_policy     = each.value.block_public_policy
  ignore_public_acls      = each.value.ignore_public_acls
  restrict_public_buckets = each.value.restrict_public_buckets
}

##### SNS ######
resource "aws_sns_topic" "codepipeline_sns_topic" {
  for_each = local.sns_topic_config
  name     = join("-", [local.prefix, local.environment, each.value.sns_topic_cp_name, local.region])
}

resource "aws_sns_topic_subscription" "subscription" {
  for_each               = local.sns_subscriptions_config
  topic_arn              = aws_sns_topic.codepipeline_sns_topic[each.value.sns_topic_cp].arn
  protocol               = each.value.sns_subscription_protocol
  endpoint_auto_confirms = each.value.endpoint_auto_confirms
  endpoint               = each.value.sns_topic_cp_subscriptions
}


##### CLOUDWATCH #####
resource "aws_cloudwatch_log_group" "infra_provision_lg" {
  for_each          = local.cloudwatch_config
  name              = join("-", [local.prefix, local.environment, each.value.cp_lg_name, local.region])
  retention_in_days = each.value.cp_lg_retention
  tags              = each.value.tags
}

###### TF Backend ######
module "tf-backend" {
  source                      = "./terraform-backend"
  for_each                    = local.tfbackend_config
  bucket_name                 = join("-", [local.prefix, local.environment, each.value.tf_backend_bucket_name, local.region])
  dynamodb_name               = join("-", [local.prefix, local.environment, each.value.tf_backend_dynamodb_name, local.region])
  bucket_tags                 = each.value.tf_backend_bucket_tags
  dynamodb_tags               = each.value.tf_backend_dynamodb_tags
  iac_role_name               = local.pipeline_shared ? local.iac_role_name : join("-", [local.prefix, local.environment, each.value.iac_role_name, local.region])
  target_account_id           = local.pipeline_shared ? local.target_account_id : data.aws_caller_identity.current.account_id
  account_id                  = data.aws_caller_identity.current.account_id
  tf_backend_role_name        = join("-", [local.prefix, local.environment, each.value.tf_backend_role_name, local.region])
  tf_backend_role_tags        = each.value.tf_backend_role_tags
  tf_backend_role_policy_name = join("-", [local.prefix, local.environment, each.value.tf_backend_role_policy_name, local.region])
}
