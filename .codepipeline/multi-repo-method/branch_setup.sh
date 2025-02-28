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
if [[ -z "$REPOSITORY_NAME" ]]; then
    echo "REPOSITORY_NAME = $REPOSITORY_NAME"
    echo "REPOSITORY_NAME must be set. Cannot proceed."
    exit 1
fi


LATEST_COMMIT_ID=""

# Populate repo with all files contained in ´.repo_init´
for file in "$REPO_DIR"/*; do
    [ -f "$file" ] || continue  # Skip directories
    filename=$(basename "$file")

    echo "Uploading: $filename"

    if [ -z "$LATEST_COMMIT_ID" ]; then
        # No parent is required for first commit
        aws codecommit put-file \
            --repository-name "$REPOSITORY_NAME" \
            --branch-name "$BRANCH_NAME" \
            --file-path "$filename" \
            --file-content fileb://"$file" \
            --commit-message "Adding $filename"
    else
        # parent commit id is required for subsequent commits
        aws codecommit put-file \
            --repository-name "$REPOSITORY_NAME" \
            --branch-name "$BRANCH_NAME" \
            --file-path "$filename" \
            --file-content fileb://"$file" \
            --commit-message "Adding $filename" \
            --parent-commit-id "$LATEST_COMMIT_ID"
    fi
    if [[ $? -ne 0 ]]; then 
        echo "Upload Failed $filename"
        exit 1
    fi
    LATEST_COMMIT_ID=$(aws codecommit get-branch --repository-name "$REPOSITORY_NAME" --branch-name "$BRANCH_NAME" --query 'branch.commitId' --output text)
done

if [[ -z "$LATEST_COMMIT_ID" || "$LATEST_COMMIT_ID" == "None" ]]; then
    echo "Not valid commit id. Cannot proceed"
    exit 1
fi

# end