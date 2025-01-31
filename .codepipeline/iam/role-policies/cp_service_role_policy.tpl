{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:Get*",
        "s3:List*",
        "s3:Put*"
      ],
      "Resource": [
        "${cp_artifact_bucket_arn}",
        "${cp_artifact_bucket_arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
        "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sns:Publish",
        "sns:CreateTopic",
        "sns:GetTopicAttributes",
        "sns:ListTagsForResource",
        "sns:Subscribe",
        "sns:Unsubscribe",
        "sns:DeleteTopic",
        "sns:GetSubscriptionAttributes"
      ],
        "Resource": "*"
    },
     {
         "Effect": "Allow",
         "Action": "codestar-connections:UseConnection",
         "Resource": "*"
     }
  ]
}
