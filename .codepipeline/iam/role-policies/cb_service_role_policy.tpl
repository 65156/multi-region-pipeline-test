{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": "*",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterfacePermission"
      ],
      "Resource": [
        "arn:${data_aws_partition_current_partition}:ec2:${data_aws_region_current_name}:${data_aws_caller_identity_current_account_id}:network-interface/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:List*",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "${cp_artifact_bucket_arn}",
        "${cp_artifact_bucket_arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": [
        "arn:${data_aws_partition_current_partition}:iam::${target_account_id}:role/${iac_role_name}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": [
        "arn:${data_aws_partition_current_partition}:iam::${shared_account_id}:role/${shared_account_role}"
      ]
    }
  ]
}
