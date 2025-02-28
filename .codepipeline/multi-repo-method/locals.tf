locals {
  input_yaml = yamldecode(file("deployment.yaml"))
  # Name Construction
  # -----------------
  customer_prefix       = try(local.input_yaml["customer_prefix"])
  project_uid           = try(local.input_yaml["project_uid"])
  full_resource_prefix  = "${local.customer_prefix}-${local.project_uid}"

  # List Building
  # -------------
  cicd = try(local.input_yaml["cicd"], {})
  handler_ref = try(local.input_yaml["lambda_automation"])
  handler_selection = local.handler_ref == "FULL_AUTO" ? "handler-automatic-close-and-merge.py" : (local.handler_ref == "AUTO_CLOSE" ? "handler-automatic-close.py" : (local.handler_ref == "APPROVE_ONLY" ? "handler.py" : null ))
  region = try(local.input_yaml["region"])
  # >>>> Repositories
  repositories_deploy = try(flatten([
    for val in local.cicd["repositories"] : [
      for templates in val["attach_templates"] : {
        id                 = val["id"]
        name               = val["id"]
        reference_existing = val["reference_existing"]
        approval_templates = val["attach_templates"]
      } if tostring(val["reference_existing"]) == "false"
    ]
    ]
  ), {})

  repositories_existing = try(flatten([
    for val in local.cicd["repositories"] : [
      for templates in val["attach_templates"] : {
        id                 = val["id"]
        name               = val["id"]
        reference_existing = val["reference_existing"]
      } if tostring(val["reference_existing"]) == "true"
    ]
    ]
  ), {})

  # >>>> Approval Templates
  approval_templates_deploy = try(flatten([
    for val in local.cicd["approval_templates"] : [
      for mem in val["pool_members"] : {
        id                 = val["id"]
        name               = val["id"]
        reference_existing = val["reference_existing"]
        approvals_needed   = val["approvals_needed"]
        pool_members       = val["attach_pool_members"]
      } if tostring(val["reference_existing"]) == "false"
    ]
    ]
  ), {})

  approval_templates_existing = try(flatten([
    for val in local.cicd["approval_templates"] : {
      id                 = val["id"]
      name               = val["id"]
      reference_existing = val["reference_existing"]
    } if tostring(val["reference_existing"]) == "true"
  ]), {})

  # >>>> IAM Assumed Roles 
  codecommit_reviewers_existing = try(flatten([
    for val in local.cicd["reviewers_iam_roles"] : {
      id                 = val["id"]
      name               = val["id"]
    } 
  ]), {})
  # <<<<<<< END OF LOCALS
}