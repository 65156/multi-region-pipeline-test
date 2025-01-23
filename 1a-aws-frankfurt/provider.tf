terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.66.0"
    }
  }
}

provider "ibm" {
  region           = "us-east"
  ibmcloud_api_key = var.AUTH_KEY
}
