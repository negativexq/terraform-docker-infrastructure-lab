SHELL := /bin/sh
TFVARS ?= terraform.tfvars
PYTHON ?= python3
ENVIRONMENT ?= development
CONTAINER_NAME_PREFIX ?= terraform-docker-lab
NETWORK_NAME ?= $(CONTAINER_NAME_PREFIX)-$(ENVIRONMENT)-network
K6_IMAGE ?= grafana/k6:2.1.0@sha256:65c920dc067d5e2e00befbf982af6ad6ad0117034e8b1c65817c7975c52d4669
K6_BASE_URL ?= http://$(CONTAINER_NAME_PREFIX)-$(ENVIRONMENT)-nginx:80
K6_RUN = docker run --rm --network $(NETWORK_NAME) -v "$(CURDIR)/k6:/scripts:ro" -e K6_BASE_URL="$(K6_BASE_URL)" $(K6_IMAGE) run

.PHONY: init fmt validate plan apply destroy test terraform-test check security tflint trivy hadolint gitleaks load-smoke load-test alert-test-error alert-test-latency alert-test-down alert-test

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

load-smoke:
	$(K6_RUN) /scripts/smoke.js

load-test:
	$(K6_RUN) /scripts/load.js

alert-test-error:
	ENVIRONMENT=$(ENVIRONMENT) CONTAINER_NAME_PREFIX=$(CONTAINER_NAME_PREFIX) NETWORK_NAME=$(NETWORK_NAME) K6_IMAGE="$(K6_IMAGE)" scripts/test-alerts.sh error

alert-test-latency:
	ENVIRONMENT=$(ENVIRONMENT) CONTAINER_NAME_PREFIX=$(CONTAINER_NAME_PREFIX) NETWORK_NAME=$(NETWORK_NAME) K6_IMAGE="$(K6_IMAGE)" scripts/test-alerts.sh latency

alert-test-down:
	ENVIRONMENT=$(ENVIRONMENT) CONTAINER_NAME_PREFIX=$(CONTAINER_NAME_PREFIX) NETWORK_NAME=$(NETWORK_NAME) K6_IMAGE="$(K6_IMAGE)" scripts/test-alerts.sh down

alert-test:
	ENVIRONMENT=$(ENVIRONMENT) CONTAINER_NAME_PREFIX=$(CONTAINER_NAME_PREFIX) NETWORK_NAME=$(NETWORK_NAME) K6_IMAGE="$(K6_IMAGE)" scripts/test-alerts.sh all

terraform-test:
	terraform init -backend=false
	terraform test

check: validate terraform-test test

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
