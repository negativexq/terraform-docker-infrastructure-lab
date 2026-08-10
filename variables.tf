variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "development"

  validation {
    condition     = contains(["development", "production"], var.environment)
    error_message = "environment must be either development or production."
  }
}

variable "nginx_port" {
  description = "Host port exposed by the Nginx reverse proxy."
  type        = number
  default     = 8080

  validation {
    condition     = var.nginx_port >= 1024 && var.nginx_port <= 65535
    error_message = "nginx_port must be between 1024 and 65535."
  }
}

variable "nginx_image" {
  description = "Pinned Nginx image tag."
  type        = string
  default     = "nginx:1.27.5-alpine"

  validation {
    condition     = can(regex("^nginx:[^:]+$", var.nginx_image))
    error_message = "nginx_image must be an nginx image with a pinned tag."
  }
}

variable "postgres_image" {
  description = "Pinned PostgreSQL image tag."
  type        = string
  default     = "postgres:16.8-alpine"

  validation {
    condition     = can(regex("^postgres:[^:]+$", var.postgres_image))
    error_message = "postgres_image must be a postgres image with a pinned tag."
  }
}

variable "app_image" {
  description = "Local tag used for the FastAPI image."
  type        = string
  default     = "terraform-docker-lab-api:local"

  validation {
    condition     = length(var.app_image) > 0
    error_message = "app_image must not be empty."
  }
}

variable "prometheus_image" {
  description = "Pinned Prometheus image tag."
  type        = string
  default     = "prom/prometheus:v3.2.1"

  validation {
    condition     = can(regex("^prom/prometheus:[^:]+$", var.prometheus_image))
    error_message = "prometheus_image must be a Prometheus image with a pinned tag."
  }
}

variable "grafana_image" {
  description = "Pinned Grafana image tag."
  type        = string
  default     = "grafana/grafana:11.5.2"

  validation {
    condition     = can(regex("^grafana/grafana:[^:]+$", var.grafana_image))
    error_message = "grafana_image must be a Grafana image with a pinned tag."
  }
}

variable "alertmanager_image" {
  description = "Pinned Alertmanager image tag."
  type        = string
  default     = "prom/alertmanager:v0.32.1"

  validation {
    condition     = can(regex("^prom/alertmanager:[^:]+$", var.alertmanager_image))
    error_message = "alertmanager_image must be an Alertmanager image with a pinned tag."
  }
}

variable "mailpit_image" {
  description = "Pinned Mailpit image tag."
  type        = string
  default     = "axllent/mailpit:v1.30.0"

  validation {
    condition     = can(regex("^axllent/mailpit:[^:]+$", var.mailpit_image))
    error_message = "mailpit_image must be a Mailpit image with a pinned tag."
  }
}

variable "prometheus_port" {
  description = "Host port exposed by Prometheus."
  type        = number
  default     = 9090

  validation {
    condition     = var.prometheus_port >= 1024 && var.prometheus_port <= 65535
    error_message = "prometheus_port must be between 1024 and 65535."
  }
}

variable "grafana_port" {
  description = "Host port exposed by Grafana."
  type        = number
  default     = 3000

  validation {
    condition     = var.grafana_port >= 1024 && var.grafana_port <= 65535
    error_message = "grafana_port must be between 1024 and 65535."
  }
}

variable "alertmanager_port" {
  description = "Host port exposed by Alertmanager."
  type        = number
  default     = 9093

  validation {
    condition     = var.alertmanager_port >= 1024 && var.alertmanager_port <= 65535
    error_message = "alertmanager_port must be between 1024 and 65535."
  }
}

variable "mailpit_web_port" {
  description = "Host port exposed by the Mailpit web interface."
  type        = number
  default     = 8025

  validation {
    condition     = var.mailpit_web_port >= 1024 && var.mailpit_web_port <= 65535
    error_message = "mailpit_web_port must be between 1024 and 65535."
  }
}

variable "container_name_prefix" {
  description = "Prefix applied to Docker container names."
  type        = string
  default     = "terraform-docker-lab"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_-]*$", var.container_name_prefix))
    error_message = "container_name_prefix may contain lowercase letters, numbers, underscores and hyphens."
  }
}

variable "postgres_db" {
  description = "PostgreSQL database name."
  type        = string
  default     = "appdb"

  validation {
    condition     = can(regex("^[a-zA-Z_][a-zA-Z0-9_]*$", var.postgres_db))
    error_message = "postgres_db must be a valid PostgreSQL identifier."
  }
}

variable "postgres_user" {
  description = "PostgreSQL application user."
  type        = string
  default     = "appuser"

  validation {
    condition     = can(regex("^[a-zA-Z_][a-zA-Z0-9_]*$", var.postgres_user))
    error_message = "postgres_user must be a valid PostgreSQL identifier."
  }
}

variable "postgres_password" {
  description = "PostgreSQL password. Supply this through a local, ignored tfvars file or an environment variable."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.postgres_password) >= 8
    error_message = "postgres_password must contain at least 8 characters."
  }
}

variable "grafana_admin_password" {
  description = "Grafana admin password for the local lab."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.grafana_admin_password) >= 8
    error_message = "grafana_admin_password must contain at least 8 characters."
  }
}
