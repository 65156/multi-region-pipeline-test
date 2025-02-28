#       ---------------------------------------------
#   ▪  ▄▄▄▄· • ▌ ▄ ·.     .▄▄ ·  ▄▄▄·      ▄▄▄  ▄▄▄▄▄.▄▄ · 
#   ██ ▐█ ▀█▪·██ ▐███▪    ▐█ ▀. ▐█ ▄█▪     ▀▄ █·•██  ▐█ ▀. 
#   ▐█·▐█▀▀█▄▐█ ▌▐▌▐█·    ▄▀▀▀█▄ ██▀· ▄█▀▄ ▐▀▀▄  ▐█.▪▄▀▀▀█▄
#   ▐█▌██▄▪▐███ ██▌▐█▌    ▐█▄▪▐█▐█▪·•▐█▌.▐▌▐█•█▌ ▐█▌·▐█▄▪▐█
#   ▀▀▀·▀▀▀▀ ▀▀  █▪▀▀▀     ▀▀▀▀ .▀    ▀█▄▀▪.▀  ▀ ▀▀▀  ▀▀▀▀ 
#       ---------------------------------------------
## >> .summary
# builds out a single AWS codecommit repository with multiple branche support, includes 2 stage codebuild and a single 
# shared lambda function for enabling CICD automation in codecommit.

# define locals
locals {
  repositories                 = aws_codecommit_repository.this.repository_name
  approval_templates_reviewers = values(aws_codecommit_approval_rule_template.reviewers)[*].name
  default_branch               = one(try([ for val in local.branches_deploy : val.id if(val.default == true)]))
  branch_list                  = [for val in local.branches_deploy : val.id]
  approval_templates           = concat(local.approval_templates_reviewers, [tostring(aws_codecommit_approval_rule_template.cicd.name)])
  template_associations_input  = setproduct([local.repositories], local.approval_templates)
  template_associations = [
    for item in local.template_associations_input : merge({ repo = item[0] }, { template = item[1] })
  ]
}

# codecommit repo
resource "aws_codecommit_repository" "this" {
  repository_name = "${local.full_resource_prefix}-${local.repository_name}"
  description     = "${local.repository_name} repository"
}
# local exec to create branches, set default? and remove main.
resource "null_resource" "create_branches" {
  provisioner "local-exec" {
    command = "branch_setup.sh"
    interpreter= ["/bin/bash", "-e"]
    environment = {
      REGION = local.region
      REPOSITORY_NAME = aws_codecommit_repository.this.repository_name
      BRANCHES = join(" ", local.branch_list)
      DEFAULT_BRANCH = local.default_branch
    }
  }
}
# codecommit repo Rules
resource "aws_codecommit_approval_rule_template" "cicd" {
  name        = "PullRequestAutomation-${local.project_uid}"
  description = "Approval rule template for CICD Lambda function "
  content = jsonencode({
    Version               = "2018-11-08"
    DestinationReferences = [for i in local.branches_deploy : "refs/heads/${i.id}"]
    Statements = [{
      Type                    = "Approvers"
      NumberOfApprovalsNeeded = 1
      ApprovalPoolMembers     = ["arn:aws:sts::${data.aws_caller_identity.source.account_id}:assumed-role/${aws_iam_role.cicd.id}/*"]
    }]
  })
  depends_on = [ null_resource.create_branches ]
}

resource "aws_codecommit_approval_rule_template" "reviewers" {
  for_each    = { for entry in local.approval_templates_deploy : "${entry.id}" => entry }
  name        = "${local.full_resource_prefix}-${each.value.name}"
  description = "additional approval rule template for use across multiple repositories"
  content = jsonencode({
    Version               = "2018-11-08"
    DestinationReferences = [for i in each.value.target_branches : "refs/heads/${i}"]
    Statements = [{
      Type                    = "Approvers"
      NumberOfApprovalsNeeded = each.value.approvals_needed
      ApprovalPoolMembers     = [for i in each.value.pool_members : "arn:aws:sts::${data.aws_caller_identity.source.account_id}:assumed-role/${i}/*"]

    }]
  })
  depends_on = [ null_resource.create_branches ]
}

resource "aws_codecommit_approval_rule_template_association" "this" {
  for_each                    = { for i in local.template_associations : "${i.repo}-${i.template}" => i }
  approval_rule_template_name = each.value.template
  repository_name             = aws_codecommit_repository.this.repository_name
  depends_on                  = [ null_resource.create_branches ]
}

data "aws_caller_identity" "source" {
}
# codecommit IAM roles
data "aws_iam_role" "reviewers" {
  for_each           = { for entry in local.codecommit_reviewers_existing : "${entry.id}" => entry }
  name               = each.value
}

resource "aws_iam_policy_attachment" "reviewers" {
  for_each   = { for entry in local.codecommit_reviewers_existing : "${entry.id}" => entry }
  name       = "code-reviewers-${each.value.name}-${local.project_uid}-attachment"
  roles      = [data.aws_iam_role.reviewers[each.value.name].name]
  policy_arn = aws_iam_policy.reviewers[1].arn
}
resource "aws_iam_policy" "reviewers" {
  count       = data.aws_iam_role.reviewers == "" ? 1 : 0
  name        = "code-reviewers-${local.project_uid}-policy"
  description = "code reviewers policy for cicd"
  policy      = data.aws_iam_policy_document.reviewers[1].json
}
data "aws_iam_policy_document" "reviewers" {
  count       = data.aws_iam_role.reviewers == "" ? 1 : 0
  statement {
    effect = "Allow"
    resources = [for i in values(aws_codecommit_repository.this)[*] : i.arn]
    actions = [
      "codecommit:UpdatePullRequestApprovalState",
      "codecommit:UpdatePullRequestStatus",
      "codecommit:PostCommentForPullRequest",
      "codecommit:Merge*",
      "codecommit:GetPullRequest",
      "codecommit:GitPull"
      ]
  }
}
resource "aws_iam_role" "cicd" {
  name               = "cicd-automation-${local.project_uid}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com","codebuild.amazonaws.com","events.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_policy_attachment" "cicd" {
  name       = "cicd-automation-${local.project_uid}-attachment"
  roles      = [aws_iam_role.cicd.name]
  policy_arn = aws_iam_policy.cicd.arn
}
resource "aws_iam_policy" "cicd" {
  name        = "cicd-automation-${local.project_uid}-policy"
  description = "cicd policy"
  policy      = data.aws_iam_policy_document.cicd.json
}
data "aws_iam_policy_document" "cicd" {
  statement {
    effect = "Allow"
    resources = ["*"]
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
      ]
  }
  statement {
    effect = "Allow"
    resources = ["arn:aws:s3:::codepipeline-${local.region}-*"]
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
      ]
  }
  statement {
    effect = "Allow"
    resources = ["${aws_codecommit_repository.this.arn}"]
    actions = [
      "codecommit:UpdatePullRequestApprovalState",
      "codecommit:UpdatePullRequestStatus",
      "codecommit:PostCommentForPullRequest",
      "codecommit:Merge*",
      "codecommit:GetPullRequest",
      "codecommit:GitPull"
      ]
  }
  statement {
    effect    = "Allow"
    resources = [for i in values(aws_codebuild_project.pr)[*] : i.arn]
    actions   = [
      "codebuild:StartBuild",
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages"
      ]
  }
  statement {
    effect    = "Allow"
    resources = [for i in values(aws_codebuild_project.build)[*] : i.arn]
    actions   = [
      "codebuild:StartBuild",
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages"
      ]
  }
}
# codebuild - test execution environment triggers
resource "aws_cloudwatch_event_rule" "pr" {
  for_each    = { for entry in local.branches_deploy : "${entry.id}" => entry }
  name        = "${local.project_uid}-${each.value.name}-codebuild-pr-rule"
  description = "initiates test execution environment on PR"

  event_pattern = jsonencode({
    resources = [tostring(aws_codecommit_repository.this.arn)]
    detail = {
      destinationReference = ["refs/heads/${each.value.id}"],
      event = ["pullRequestCreated", "pullRequestSourceBranchUpdated"]
    }
    source = ["aws.codecommit"]
  })
  role_arn = aws_iam_role.cicd.arn
}

resource "aws_cloudwatch_event_target" "pr" {
  for_each = { for entry in local.branches_deploy : "${entry.id}" => entry }
  rule     = aws_cloudwatch_event_rule.pr["${each.value.id}"].name
  arn      = aws_codebuild_project.pr["${each.value.id}"].arn
  role_arn  = aws_iam_role.cicd.arn
  input_transformer {
    input_paths = {
      detail-destinationCommit  = "$.detail.destinationCommit",
      detail-pullRequestId      = "$.detail.pullRequestId",
      detail-repositoryNames-0- = "$.detail.repositoryNames[0]",
      detail-revisionId         = "$.detail.revisionId",
      detail-sourceCommit       = "$.detail.sourceCommit"
    }
    input_template = <<EOF
{"sourceIdentifier":<detail-repositoryNames-0->,"sourceVersion":<detail-sourceCommit>,"artifactsOverride":{"type":"NO_ARTIFACTS"},"environmentVariablesOverride":[{"name":"PULL_REQUEST_ID","value":<detail-pullRequestId>,"type":"PLAINTEXT"},{"name":"REPOSITORY_NAME","value":<detail-repositoryNames-0->,"type":"PLAINTEXT"},{"name":"SOURCE_COMMIT","value":<detail-sourceCommit>,"type":"PLAINTEXT"},{"name":"DESTINATION_COMMIT","value":<detail-destinationCommit>,"type":"PLAINTEXT"},{"name":"REVISION_ID","value":<detail-revisionId>,"type":"PLAINTEXT"}]}
EOF 
  }
}

# codebuild - test phase
resource "aws_codebuild_project" "pr" {
  for_each      = { for entry in local.branches_deploy : "${entry.id}" => entry }
  name          = "${local.project_uid}-${each.value.name}-pr"
  description   = "${each.value.name} pr execution environment"
  build_timeout = 5
  service_role  = aws_iam_role.cicd.arn #should be the lambda ARN for automation
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }
  }
  source {
    type            = "CODECOMMIT"
    location        = aws_codecommit_repository.this.clone_url_http
    git_clone_depth = 1
    buildspec       = "buildspec-pr.yaml"
  }
  source_version = "refs/heads/${each.value.id}"
}

# codebuild - lambda execution triggers
resource "aws_cloudwatch_event_rule" "lambda" {
  for_each = { for entry in local.branches_deploy : "${entry.id}" => entry }
  name     = "${local.project_uid}-${each.value.name}-lamda-execution"

  description = "initiates lambda function on codebuild test execution outcome"

  event_pattern = jsonencode({
    detail-type = ["CodeBuild Build State Change"],
    source      = ["aws.codebuild"],
    detail = {
      project-name = [tostring(aws_codebuild_project.pr["${each.value.id}"].name)]
    }
  })
  role_arn = aws_iam_role.cicd.arn
}
resource "aws_cloudwatch_event_target" "lambda" {
  for_each = { for entry in local.branches_deploy : "${entry.id}" => entry }
  rule     = aws_cloudwatch_event_rule.lambda["${each.value.id}"].id
  arn      = aws_lambda_function.lambda.arn
  #role_arn = aws_iam_role.cicd.arn
  depends_on = [aws_lambda_permission.invoke]
}

# lambda function
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda/${local.handler_selection}"
  output_path = "lambda_function_payload.zip"
}
resource "aws_lambda_permission" "invoke" {
  for_each = { for entry in local.branches_deploy : "${entry.id}" => entry }
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.lambda["${each.value.id}"].arn}"
}
resource "aws_lambda_function" "lambda" {
  filename      = "lambda_function_payload.zip"
  function_name = "PullRequestAutomation-${local.project_uid}"
  role          = aws_iam_role.cicd.arn
  handler       = "${trimsuffix(local.handler_selection, ".py")}.lambda_handler"

  runtime = "python3.9"

}

# codebuild - build exeuction environment triggers #TODO
resource "aws_cloudwatch_event_rule" "build" {
  for_each    = { for entry in local.branches_deploy : "${entry.id}" => entry }
  name        = "${local.project_uid}-${each.value.name}-codebuild-merge-rule"
  description = "initiates build execution environment on PR merge"

  event_pattern = jsonencode({
    resources = [tostring(aws_codecommit_repository.this.arn)]
    detail = {
    #  referenceName = ["${each.value.id}"],
      destinationReference = ["refs/heads/${each.value.id}"],
      event = ["pullRequestMergeStatusUpdated"],
      isMerged = ["True"]
    }
    source = ["aws.codecommit"]
  })
  role_arn = aws_iam_role.cicd.arn
}

resource "aws_cloudwatch_event_target" "build" {
  for_each = { for entry in local.branches_deploy : "${entry.id}" => entry }
  rule     = aws_cloudwatch_event_rule.build["${each.value.id}"].name
  arn      = aws_codebuild_project.build["${each.value.id}"].arn
  role_arn  = aws_iam_role.cicd.arn
}

# codebuild - build phase
resource "aws_codebuild_project" "build" {
  for_each      = { for entry in local.branches_deploy : "${entry.id}" => entry }
  name          = "${local.project_uid}-${each.value.name}-build"
  description   = "${each.value.name} build execution environment"
  build_timeout = 5
  service_role  = aws_iam_role.cicd.arn #should be the lambda ARN for automation

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }
  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }
  }
  source {
    type            = "CODECOMMIT"
    location        = aws_codecommit_repository.this.clone_url_http
    git_clone_depth = 1
    buildspec       = "buildspec-build.yaml"
  }
  source_version = "refs/heads/${each.value.id}"

}
