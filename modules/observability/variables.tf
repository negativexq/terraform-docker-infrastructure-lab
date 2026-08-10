variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "container_name_prefix" {
  description = "Prefix applied to observability container names."
  type        = string
}

variable "network_name" {
  description = "Shared Docker network name from the network module."
  type        = string
}

variable "prometheus_config_dir" {
  description = "Absolute path to the Prometheus config directory, including rules/."
  type        = string
}

variable "alertmanager_config_dir" {
  description = "Absolute path to the Alertmanager config directory."
  type        = string
}

variable "grafana_config_dir" {
  description = "Absolute path to the Grafana provisioning and dashboards directory."
  type        = string
}

variable "prometheus_image" {
  description = "Pinned Prometheus image tag."
  type        = string
}

variable "prometheus_port" {
  description = "Host port exposed by Prometheus."
  type        = number
}

variable "grafana_image" {
  description = "Pinned Grafana image tag."
  type        = string
}

variable "grafana_port" {
  description = "Host port exposed by Grafana."
  type        = number
}

variable "grafana_admin_password" {
  description = "Grafana admin password for the local lab."
  type        = string
  sensitive   = true
}

variable "alertmanager_image" {
  description = "Pinned Alertmanager image tag."
  type        = string
}

variable "alertmanager_port" {
  description = "Host port exposed by Alertmanager."
  type        = number
}

variable "mailpit_image" {
  description = "Pinned Mailpit image tag."
  type        = string
}

variable "mailpit_web_port" {
  description = "Host port exposed by the Mailpit web interface."
  type        = number
}
