SHELL := /bin/sh
TFVARS ?= terraform.tfvars
PYTHON ?= python3

.PHONY: init fmt validate plan apply destroy test security tflint trivy hadolint gitleaks

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
	$(PYTHON) -m pip check
	$(PYTHON) -m pytest app
	$(PYTHON) -m ruff check app

security: tflint trivy hadolint gitleaks

tflint:
	@command -v tflint >/dev/null 2>&1 || { echo "Error: tflint is not installed. See https://github.com/terraform-linters/tflint#installation"; exit 127; }
	tflint --recursive --config "$(CURDIR)/.tflint.hcl"

trivy:
	@command -v trivy >/dev/null 2>&1 || { echo "Error: trivy is not installed. See https://trivy.dev/latest/getting-started/installation/"; exit 127; }
	@command -v docker >/dev/null 2>&1 || { echo "Error: Docker CLI is required to build the local FastAPI image for the image scan."; exit 127; }
	trivy config --severity HIGH,CRITICAL --exit-code 1 --skip-dirs .terraform,.venv .
	trivy fs --scanners vuln,secret --ignore-unfixed --severity HIGH,CRITICAL --exit-code 1 --skip-dirs .terraform,.venv .
	@docker info >/dev/null 2>&1 || { echo "Error: Docker daemon is unavailable; start Docker to build the local FastAPI image."; exit 1; }
	docker build --pull --no-cache --tag terraform-docker-lab-api:security ./app
	trivy image --ignore-unfixed --severity HIGH,CRITICAL --exit-code 1 terraform-docker-lab-api:security

hadolint:
	@command -v hadolint >/dev/null 2>&1 || { echo "Error: hadolint is not installed. See https://github.com/hadolint/hadolint#install"; exit 127; }
	hadolint app/Dockerfile

gitleaks:
	@command -v gitleaks >/dev/null 2>&1 || { echo "Error: gitleaks is not installed. See https://github.com/gitleaks/gitleaks#installation"; exit 127; }
	gitleaks git --redact --exit-code 1 --config .gitleaks.toml
	gitleaks dir --redact --exit-code 1 --config .gitleaks.toml .
