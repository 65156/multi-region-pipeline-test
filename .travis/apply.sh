# apply.sh
FG="\033[4m"
STYLE0="\033[33;44m"
STYLE1="\033[34;41m"
NUM=0

echo "->"
echo "--->"
echo "----->"
echo "------->"
echo "--------->"
echo -e ${FG}${STYLE0} Executing Terraform Apply - ${TRAVIS_BRANCH}
echo ""

echo ""
((NUM++)); echo -e ${STYLE1}\[STEP ${NUM}\] - initalizing terraform
wget -q https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip
unzip terraform_${TF_VERSION}_linux_amd64.zip
sudo mv terraform /usr/local/bin/
cd ${WORKING_DIR}
echo Working Directory: ${WORKING_DIR}
echo Target Branch: ${TRAVIS_BRANCH}
echo Job Name: ${TRAVIS_JOB_NAME}
terraform init \
    -backend-config="key=${TRAVIS_JOB_NAME}/${TRAVIS_BRANCH}.tfstate" \
    -backend-config="bucket=${TF_BUCKET}" \
    -backend-config="region=${TF_REGION}"

echo ""
((NUM++)); echo -e ${FG}${STYLE1}\[STEP ${NUM}\] - running terraform apply
terraform apply -auto-approve -input=false
#echo "running terraform apply"