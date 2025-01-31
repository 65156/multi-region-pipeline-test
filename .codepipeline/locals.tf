locals {
  input_yaml = yamldecode(file("${path.module}/deployment.yaml"))
  customer            = local.input_yaml["customer"]
  prefix              = local.input_yaml["customer"]["prefix"]
  environment         = local.input_yaml["customer"]["env"]
  #architecture        = local.input_yaml["customer"]["architecture"]
  #orchestrator        = local.input_yaml["customer"]["orchestrator"]
  #built_by            = local.input_yaml["customer"]["built_by"]
  #compliance          = local.input_yaml["customer"]["compliance"]
  #data_classification = local.input_yaml["customer"]["data_classification"]
  #components          = local.input_yaml["customer"]["components"]
  #iac_version         = local.input_yaml["customer"]["iac_version"]
  #zone                = local.input_yaml["customer"]["zone"]
  #customer_id         = local.input_yaml["customer"]["id"]
  #program             = local.input_yaml["customer"]["program"]
  #landscape           = local.input_yaml["customer"]["landscape"]
  target_account_id   = local.input_yaml["customer"]["target_account_id"]
  iac_role_name       = local.input_yaml["customer"]["iac_role_name"]
  cloud           = local.input_yaml["cloud"]["sites"]
  cloud_id        = local.input_yaml["cloud"]["id"]
  site            = local.input_yaml["customer"]["site"]
  region          = { for site in local.cloud : site.site => { region = site.region } }[local.site].region
  #location        = { for site in local.cloud : site.site => { location = site.cloud_region } }[local.site].location
  pipeline_deploy  = try(tostring(local.input_yaml["pipeline"]["deploy"]), {})
  pipeline_shared  = try(tostring(local.input_yaml["pipeline"]["shared"]), {})
  storage_config   = try({ for val in local.input_yaml["pipeline"]["storage"]["buckets"] : val.id => val if(tostring(val.deploy) == "true" && local.pipeline_deploy == "true") }, {})
  storage_existing = try({ for val in local.input_yaml["pipeline"]["storage"]["buckets"] : val.id => val if(tostring(val.deploy) == "false" || local.pipeline_deploy == "false") }, {})
  s3_buckets = {
    for k, v in local.storage_config :
    k => aws_s3_bucket.cp_artifact_bucket[k].id
  }

  iam_roles_config   = try({ for val in local.input_yaml["pipeline"]["iam"]["roles"] : val.id => val if(tostring(val.deploy) == "true" && local.pipeline_deploy == "true") }, {})
  iam_roles_existing = try({ for val in local.input_yaml["pipeline"]["iam"]["roles"] : val.id => val if(tostring(val.deploy) == "false" || local.pipeline_deploy == "false") }, {})
  iam_roles = {
    for k, v in local.iam_roles_config :
    k => aws_iam_role.role[k].arn
  }

  iam_policy_config   = try({ for val in local.input_yaml["pipeline"]["iam"]["policy"] : val.id => val if(tostring(val.deploy) == "true" && local.pipeline_deploy == "true") }, {})
  iam_policy_existing = try({ for val in local.input_yaml["pipeline"]["iam"]["policy"] : val.id => val if(tostring(val.deploy) == "false" || local.pipeline_deploy == "false" || local.pipeline_shared == "false") }, {})
  codestar_config     = try({ for val in local.input_yaml["pipeline"]["codestar"] : val.id => val if(tostring(val.deploy) == "true" && local.pipeline_deploy == "true") }, {})
  codestar_existing   = try({ for val in local.input_yaml["pipeline"]["codestar"] : val.id => val if(tostring(val.deploy) == "false" || local.pipeline_deploy == "false") }, {})
  codepipeline_config = try({ for val in local.input_yaml["pipeline"]["codepipeline"] : val.id => val if(tostring(val.deploy) == "true" && local.pipeline_deploy == "true") }, {})

  cp_stage_source_actions = flatten([
    for v in local.codepipeline_config : [
      for s in v["stage"] : [
        for a in s["action"] :
        {
          name                 = tostring(a["name"])
          codestar_connection  = tostring(a["codestar_connection"])
          iac_repo_name        = tostring(a["iac_repo_name"])
          iac_repo_branch_name = tostring(a["iac_repo_branch_name"])
          outputartifactformat = a["outputartifactformat"]
          detectchanges        = tostring(a["detectchanges"])
          projectname          = tostring(a["projectname"])
          sns_topic            = tostring(a["sns_topic"])
          customdata           = tostring(a["customdata"])
          externalentityLink   = tostring(a["externalentityLink"])
          category             = tostring(a["category"])
          owner                = tostring(a["owner"])
          provider             = tostring(a["provider"])
          version              = tostring(a["version"])
          output_artifacts     = a["output_artifacts"]
          input_artifacts      = a["input_artifacts"]
          namespace            = a["namespace"]
          run_order            = a["run_order"]
        } if(tostring(a.namespace) == "SOURCE")
      ]
    ] 
  ]) 
  cp_stage_approve_actions = flatten([
    for v in local.codepipeline_config : [
      for s in v["stage"] : [
        for a in s["action"] :
        {
          name                 = tostring(a["name"])
          codestar_connection  = tostring(a["codestar_connection"])
          iac_repo_name        = tostring(a["iac_repo_name"])
          iac_repo_branch_name = tostring(a["iac_repo_branch_name"])
          outputartifactformat = a["outputartifactformat"]
          detectchanges        = tostring(a["detectchanges"])
          projectname          = tostring(a["projectname"])
          sns_topic            = tostring(a["sns_topic"])
          customdata           = tostring(a["customdata"])
          externalentityLink   = tostring(a["externalentityLink"])
          category             = tostring(a["category"])
          owner                = tostring(a["owner"])
          provider             = tostring(a["provider"])
          version              = tostring(a["version"])
          output_artifacts     = a["output_artifacts"]
          input_artifacts      = a["input_artifacts"]
          namespace            = a["namespace"]
          run_order            = a["run_order"]
        } if(tostring(a.namespace) == "APPROVAL")
      ]
    ] 
  ]) 
  cp_stage_plan_actions = flatten([
    for v in local.codepipeline_config : [
      for s in v["stage"] : [
        for a in s["action"] :
        {
          name                 = tostring(a["name"])
          codestar_connection  = tostring(a["codestar_connection"])
          iac_repo_name        = tostring(a["iac_repo_name"])
          iac_repo_branch_name = tostring(a["iac_repo_branch_name"])
          outputartifactformat = a["outputartifactformat"]
          detectchanges        = tostring(a["detectchanges"])
          projectname          = tostring(a["projectname"])
          sns_topic            = tostring(a["sns_topic"])
          customdata           = tostring(a["customdata"])
          externalentityLink   = tostring(a["externalentityLink"])
          category             = tostring(a["category"])
          owner                = tostring(a["owner"])
          provider             = tostring(a["provider"])
          version              = tostring(a["version"])
          output_artifacts     = a["output_artifacts"]
          input_artifacts      = a["input_artifacts"]
          namespace            = a["namespace"]
          run_order            = a["run_order"]
        } if(tostring(a.namespace) == "PLAN")
      ]
    ] 
  ]) 
  cp_stage_apply_actions = flatten([
    for v in local.codepipeline_config : [
      for s in v["stage"] : [
        for a in s["action"] :
        {
          name                 = tostring(a["name"])
          codestar_connection  = tostring(a["codestar_connection"])
          iac_repo_name        = tostring(a["iac_repo_name"])
          iac_repo_branch_name = tostring(a["iac_repo_branch_name"])
          outputartifactformat = a["outputartifactformat"]
          detectchanges        = tostring(a["detectchanges"])
          projectname          = tostring(a["projectname"])
          sns_topic            = tostring(a["sns_topic"])
          customdata           = tostring(a["customdata"])
          externalentityLink   = tostring(a["externalentityLink"])
          category             = tostring(a["category"])
          owner                = tostring(a["owner"])
          provider             = tostring(a["provider"])
          version              = tostring(a["version"])
          output_artifacts     = a["output_artifacts"]
          input_artifacts      = a["input_artifacts"]
          namespace            = a["namespace"]
          run_order            = a["run_order"]
        } if(tostring(a.namespace) == "APPLY")
      ]
    ] 
  ]) 

  codepipeline_existing      = try({ for val in local.input_yaml["pipeline"]["codepipeline"] : val.id => val if(tostring(val.deploy) == "false" || local.pipeline_deploy == "false") }, {})
  codebuild_config           = try({ for val in local.input_yaml["pipeline"]["codebuild"] : val.id => val if(tostring(val.deploy) == "true" && local.pipeline_deploy == "true") }, {})
  codebuild_existing         = try({ for val in local.input_yaml["pipeline"]["codebuild"] : val.id => val if(tostring(val.deploy) == "false" || local.pipeline_deploy == "false") }, {})
  cloudwatch_config          = try({ for val in local.input_yaml["pipeline"]["cloudwatch"] : val.id => val if(tostring(val.deploy) == "true" && local.pipeline_deploy == "true") }, {})
  cloudwatch_existing        = try({ for val in local.input_yaml["pipeline"]["cloudwatch"] : val.id => val if(tostring(val.deploy) == "false" || local.pipeline_deploy == "false") }, {})
  tfbackend_config           = try({ for val in local.input_yaml["pipeline"]["tfbackend"] : val.id => val if(tostring(val.deploy) == "true" && local.pipeline_deploy == "true") }, {})
  tfbackend_existing         = try({ for val in local.input_yaml["pipeline"]["tfbackend"] : val.id => val if(tostring(val.deploy) == "false" || local.pipeline_deploy == "false") }, {})
  sns_topic_config           = try({ for val in local.input_yaml["pipeline"]["sns"]["topic"] : val.id => val if(tostring(val.deploy) == "true" && local.pipeline_deploy == "true") }, {})
  sns_topic_existing         = try({ for val in local.input_yaml["pipeline"]["sns"]["topic"] : val.id => val if(tostring(val.deploy) == "false" || local.pipeline_deploy == "false") }, {})
  sns_subscriptions_config   = try({ for val in local.input_yaml["pipeline"]["sns"]["subscriptions"] : val.id => val if(tostring(val.deploy) == "true" && local.pipeline_deploy == "true") }, {})
  sns_subscriptions_existing = try({ for val in local.input_yaml["pipeline"]["sns"]["subscriptions"] : val.id => val if(tostring(val.deploy) == "false" || local.pipeline_deploy == "false") }, {})
}
