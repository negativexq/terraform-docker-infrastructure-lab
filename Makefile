SHELL := /bin/sh
TFVARS ?= terraform.tfvars
PYTHON ?= python3

.PHONY: init fmt validate plan apply destroy test

init:
	terraform init

fmt:
	terraform fmt -recursive

validate: init
	terraform validate

plan: validate
	terraform plan -var-file=$(TFVARS)

apply: validate
	terraform apply -var-file=$(TFVARS)

destroy: validate
	terraform destroy -var-file=$(TFVARS)

test:
	$(PYTHON) -m pytest app
	$(PYTHON) -m ruff check app
