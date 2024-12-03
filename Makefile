.PHONY: init plan apply destroy ansible-setup ansible-run clean all

# Variables
TERRAFORM_DIR = terraform
ANSIBLE_DIR = ansible
SSH_KEY = ~/.ssh/id_rsa

init:
	cd $(TERRAFORM_DIR) && terraform init

plan:
	cd $(TERRAFORM_DIR) && terraform plan

apply:
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve

destroy:
	cd $(TERRAFORM_DIR) && terraform destroy -auto-approve

ansible-setup:
	ansible-galaxy install -r $(ANSIBLE_DIR)/requirements.yml
	chmod 400 $(SSH_KEY)

ansible-run:
	ansible-playbook -i $(ANSIBLE_DIR)/inventories/gcp.yml $(ANSIBLE_DIR)/site.yml

ansible-frontend:
	ansible-playbook -i $(ANSIBLE_DIR)/inventories/gcp.yml $(ANSIBLE_DIR)/site.yml --tags frontend

ansible-backend:
	ansible-playbook -i $(ANSIBLE_DIR)/inventories/gcp.yml $(ANSIBLE_DIR)/site.yml --tags backend

ansible-database:
	ansible-playbook -i $(ANSIBLE_DIR)/inventories/gcp.yml $(ANSIBLE_DIR)/site.yml --tags database
ans
clean:
	rm -rf $(TERRAFORM_DIR)/.terraform
	rm -f $(TERRAFORM_DIR)/terraform.tfstate*
	rm -f $(ANSIBLE_DIR)/inventories/gcp.yml

all: init apply ansible-setup ansible-run

test:
	cd $(TERRAFORM_DIR) && terraform fmt -check
	cd $(TERRAFORM_DIR) && terraform validate
	ansible-playbook -i $(ANSIBLE_DIR)/inventories/gcp.yml $(ANSIBLE_DIR)/site.yml --syntax-check

help:
	@echo "Available commands:"
	@echo "  make init          - Initialize Terraform"
	@echo "  make plan         - Plan Terraform changes"
	@echo "  make apply        - Apply Terraform changes"
	@echo "  make destroy      - Destroy infrastructure"
	@echo "  make ansible-setup - Install Ansible requirements"
	@echo "  make ansible-run  - Run Ansible playbook"
	@echo "  make clean        - Clean up generated files"
	@echo "  make all          - Deploy full infrastructure"
	@echo "  make test         - Run tests"