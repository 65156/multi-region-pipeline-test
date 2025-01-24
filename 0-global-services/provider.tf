terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.66.0"
    }
  }
}

provider "ibm" {
  region           = var.IBMC_DEFAULT_REGION
  ibmcloud_api_key = var.IBMC_AUTH_KEY
}
