# exit on error
set -e

export AWS_DEFAULT_REGION=${REGION}
REPO_DIR=".repo-init"
BRANCH_NAME="main"

# check if aws command is installed
if ! command -v aws &> /dev/null; then 
    echo "AWS CLI must be installed. Cannot proceed."
    exit 1
fi 

# ensure required variables are set
if [[ -z "$REPOSITORY_NAME" || -z "$BRANCHES" || -z "$DEFAULT_BRANCH" ]]; then
    echo "REPOSITORY_NAME = $REPOSITORY_NAME"
    echo "BRANCHES = $BRANCHES"
    echo "DEFAULT_BRANCH = $DEFAULT_BRANCH"
    echo "REPOSITORY_NAME, BRANCHES or DEFAULT_BRANCH must be set. Cannot proceed."
    exit 1
fi

LATEST_COMMIT_ID=""

# Populate repo with all files contained in ´.repo_init´
for file in `find $REPO_DIR -type f`; do
    relative_path=${file#"$REPO_DIR"}

    echo "Uploading: $relative_path"

    if [ -z "$LATEST_COMMIT_ID" ]; then
        # No parent is required for first commit
        aws codecommit put-file \
            --repository-name "$REPOSITORY_NAME" \
            --branch-name "$BRANCH_NAME" \
            --file-path "$relative_path" \
            --file-content fileb://"$file" \
            --commit-message "Adding $relative_path"
    else
        # parent commit id is required for subsequent commits
        aws codecommit put-file \
            --repository-name "$REPOSITORY_NAME" \
            --branch-name "$BRANCH_NAME" \
            --file-path "$relative_path" \
            --file-content fileb://"$file" \
            --commit-message "Adding $relative_path" \
            --parent-commit-id "$LATEST_COMMIT_ID"
    fi
    if [[ $? -ne 0 ]]; then 
        echo "Upload Failed $relative_path"
        exit 1
    fi
    LATEST_COMMIT_ID=$(aws codecommit get-branch --repository-name "$REPOSITORY_NAME" --branch-name "$BRANCH_NAME" --query 'branch.commitId' --output text)
done

if [[ -z "$LATEST_COMMIT_ID" || "$LATEST_COMMIT_ID" == "None" ]]; then
    echo "Not valid commit id. Cannot proceed"
    exit 1
fi

# branches input is a list of strings, this needs to loop through and create branches (with a commid id)
for branch in $BRANCHES; do 
    echo "Creating branch: $branch"
    aws codecommit create-branch --repository-name "$REPOSITORY_NAME" --branch-name "$branch" --commit-id "$LATEST_COMMIT_ID"
done

# update the default branch from main to whatever is defined in the var
aws codecommit update-default-branch --repository-name ${REPOSITORY_NAME} --default-branch-name ${DEFAULT_BRANCH}

# delete the main branch
aws codecommit delete-branch --repository-name ${REPOSITORY_NAME} --branch-name $BRANCH_NAME
