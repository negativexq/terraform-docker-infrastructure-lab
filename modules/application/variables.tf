variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "container_name_prefix" {
  description = "Prefix applied to application container names."
  type        = string
}

variable "network_name" {
  description = "Shared Docker network name from the network module."
  type        = string
}

variable "app_context" {
  description = "Absolute path to the FastAPI Docker build context."
  type        = string
}

variable "nginx_config_path" {
  description = "Absolute path to the Nginx configuration file."
  type        = string
}

variable "app_image" {
  description = "Local tag used for the FastAPI image."
  type        = string
}

variable "nginx_image" {
  description = "Pinned Nginx image tag."
  type        = string
}

variable "nginx_port" {
  description = "Host port exposed by the Nginx reverse proxy."
  type        = number
}

variable "postgres_image" {
  description = "Pinned PostgreSQL image tag."
  type        = string
}

variable "postgres_db" {
  description = "PostgreSQL database name."
  type        = string
}

variable "postgres_user" {
  description = "PostgreSQL application user."
  type        = string
}

variable "postgres_password" {
  description = "PostgreSQL password."
  type        = string
  sensitive   = true
}
