output "application_url" {
  description = "URL served by the Nginx reverse proxy."
  value       = "http://localhost:${var.nginx_port}"
}

output "network_name" {
  description = "Docker network used by all application services."
  value       = docker_network.app.name
}

output "postgres_volume_name" {
  description = "Persistent Docker volume used by PostgreSQL."
  value       = docker_volume.postgres.name
}
