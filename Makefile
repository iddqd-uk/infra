#!/usr/bin/make

IN_DOCKER := docker compose run --rm --user "$(shell id -u):$(shell id -g)" shell
.DELETE_ON_ERROR: # delete target file if the command fails
#.FORCE: # dummy target to force execution
.DEFAULT_GOAL = help # default target to display help

help: ## Display a list of available commands with descriptions
	@printf "\033[33m%s:\033[0m\n" 'Available commands'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  \033[32m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# --- DOCKER ----------------------------------------------------------------------------------------------------------

shell: ## Start a shell session in a Docker container with the current directory mounted
	docker compose run --rm --user "$(shell id -u):$(shell id -g)" shell sh

# --- CODE GENERATION -------------------------------------------------------------------------------------------------

dns/creds.json: ## Generate a kube config file with cluster credentials
	@test ! -f ./dns/creds.json || rm -f ./dns/creds.json # due to file permissions remove existing file first
	$(IN_DOCKER) doppler secrets substitute ./dns/creds.doppler.json > ./dns/creds.json
	@chmod 400 ./dns/creds.json # set minimal file permissions

.terraformrc: ## Generate a Terraform CLI credentials file
	@test ! -f ./.terraformrc || rm -f ./.terraformrc # due to file permissions remove existing file first
	$(IN_DOCKER) doppler secrets substitute ./.terraformrc.doppler.tf > ./.terraformrc
	@chmod 400 ./.terraformrc # set minimal file permissions

terraform/.terraform: .terraformrc ## Initialize the Terraform workspace
	$(IN_DOCKER) terraform -chdir=./terraform init

# --- DNS -------------------------------------------------------------------------------------------------------------

dns-preview: dns/creds.json ## Preview the DNS record changes
	$(IN_DOCKER) dnscontrol preview --config ./dns/dnsconfig.js --creds ./dns/creds.json

dns-push: dns/creds.json ## Push the DNS record changes
	$(IN_DOCKER) dnscontrol push --config ./dns/dnsconfig.js --creds ./dns/creds.json

# --- TERRAFORM -------------------------------------------------------------------------------------------------------

terraform-fmt: ## Format the Terraform files
	$(IN_DOCKER) terraform -chdir=./terraform fmt

terraform-plan: terraform/.terraform .terraformrc ## Plan the Terraform changes
	$(IN_DOCKER) doppler run --name-transformer tf-var -- terraform -chdir=./terraform plan

terraform-apply: terraform/.terraform .terraformrc ## Apply the Terraform changes
	$(IN_DOCKER) doppler run --name-transformer tf-var -- terraform -chdir=./terraform apply

terraform-destroy: terraform/.terraform .terraformrc ## Destroy the Terraform resources
	$(IN_DOCKER) doppler run --name-transformer tf-var -- terraform -chdir=./terraform destroy
