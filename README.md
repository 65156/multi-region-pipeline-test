## CICD Pipeline Template 001 (Github Actions)
Supports 
- [x] Multi Regions
- [x] Multi Clouds
- [x] Single Environment
- [x] Github Actions for CICD

### Usage

Update the variables.tf found inside ".backend-init" subfolder and then initialize the backend.

```
cd .backend-init
terraform init
terraform apply -auto-apply
```

Once backend has been configured, update the backend bucket arg found in each of the provider.tf files in each regional directory and re-run the github actions pipeline.