#
# Purpose:
#   ease the bootstraping and hide some terraform magic
#

ifndef env_name
$(error variable env_name not set)
endif

ifndef cloudsql_credential_filename
$(error variable cloudsql_credential_filename not set)
endif

ifndef gcloud_env_name
$(error variable env_name not set)
endif

# init terraform environment
.PHONY: terraform_init
terraform_init: 
	#remove secrets and load latest secret from gcloud
	rm -rf secrets
	gsutil -m cp -R gs://$(gcloud_env_name)_terraform/secrets/ .
	terraform get -update
	terraform init

# plan terrform with secrets
.PHONY: terraform_plan
terraform_plan:
	terraform fmt -recursive
	terraform plan -var-file secrets/terraform-$(env_name).tfvars

# apply terraform with secrets
.PHONY: terraform_apply
terraform_apply:
	# just make sure we know what we are doing
	terraform fmt -recursive
	terraform apply -var-file secrets/terraform-$(env_name).tfvars

# destroy terraform with secrets
.PHONY: terraform_destroy
terraform_destroy:
	# just make sure we know what we are doing
	terraform fmt -recursive
	terraform destroy -var-file secrets/terraform-$(env_name).tfvars

