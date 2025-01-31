# ibmauth.sh
curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
ibmcloud --version
ibmcloud config --check-version=false

# Authenticate with IBM Cloud CLI
ibmcloud login --apikey "${IBMC_AUTH_KEY}" -r "${IBMC_DEFAULT_REGION}" -g "${IBMC_RESOURCE_GROUP}"  