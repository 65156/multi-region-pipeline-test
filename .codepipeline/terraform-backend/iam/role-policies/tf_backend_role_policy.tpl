{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
                  "s3:PutObject",
                  "s3:GetObject",
                  "s3:ListBucket"
              ],
              "Effect": "Allow",
              "Resource": [
                  "${bucket-arn}/*",
                  "${bucket-arn}"
              ]
    },
    {
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:GetItem",
                "dynamodb:DeleteItem",
                "dynamodb:UpdateItem"
            ],
            "Effect": "Allow",
            "Resource": "${dynamodb-arn}"
        },
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": [
        "arn:aws:iam::${target_account_id}:role/${iac_role_name}"
      ]
    }
  ]
}
