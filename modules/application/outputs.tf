output "application_url" {
  description = "URL served by the Nginx reverse proxy."
  value       = "http://localhost:${var.nginx_port}"
}

output "postgres_volume_name" {
  description = "Persistent Docker volume used by PostgreSQL."
  value       = docker_volume.postgres.name
}
