# Multi-Region-Pipelines
Pipeline Configuration and Terraform State management for cloud infrastructure for Customer Buildout.

## Features 
- [x] Single Cloud ( AWS )
- [x] Multiple Environments
- [x] One Repository per Environment
- [ ] Single Repository with Multiple Branches (one for each environment) WIP

## Build Environment Support
- [x] AWS Codebuild

## Usage
Development runs across specific branches which correspond to different build environments and cloud accounts, service keys for deployment should be kept as secrets and variables in the build environment.

### Active Branches 
- [x] Backbone (for shared services and core infrastructure, network, security etc.)
- [x] Development
- [x] Staging
- [x] Testing
- [x] Production

#### Folders 
Each folder represents a targeted combination of development environment, cloud provider and a region, with the exception of the `0-global-services` which is used as a multiple cloud & region terraform state for the purpose of deploying cross cloud and cross regional services.

### Development Environment
Run the tf-dev.sh shell script to install your environment, this will configure terraform version manager, tflinter and detect-secrets (which will run as a git pre-commit hook).

#### Inline Allowlisting
To tell detect-secrets to ignore a particular line of code, simply append an inline pragma: allowlist secret comment. For example:

```
API_KEY = "blah-blah-but-actually-not-secret"  # pragma: allowlist secret
print('hello world')
```

### Pull Requests
Pull requests into the above active branches will trigger build checks against the target cloud environment, these checks must pass before a merge can take place.

### Merging
Merging an approved PR will initiate a build against the target cloud environment.

### Terraform Backend
- Backend configuration sits on a single AWS S3 Bucket
- Unique statefiles for each "environment" && "region", in a path format of: \region\environment.tfstate (example: \1a-aws-frankfurt\development.tfstate)
- State locking is controlled by a single DynamoDB instance
- LockIDs in DynamoDB follow statefile path as unique name

#### Backend Initialization
Update the variables.tf found inside ".backend-init" subfolder and then initialize the backend.

```
cd .backend-init
terraform init
terraform apply -auto-apply
```

Once backend has been configured, update the backend bucket arg found in each of the provider.tf files in each regional directory and re-run the pipeline.
