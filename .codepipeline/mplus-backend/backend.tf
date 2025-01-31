### DO NOT EDIT or REMOVE THIS FILE
### Backend will be added by the program
terraform {
  backend "s3" {
    bucket = "pesispwld-pesnetwork-us-east-2pr-backend"
    key = "isp/s3/terraform.tfstate"
    region = "us-east-2"
    dynamodb_table = "pesispwld-pesnetwork-us-east-2pr-ddbtbl"
    encrypt = true

  #  #role_arn = "arn:aws:iam::<acct-id-having-bucket>:role/xyz"
  }
}
