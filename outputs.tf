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

output "prometheus_url" {
  description = "URL for the Prometheus UI."
  value       = "http://localhost:${var.prometheus_port}"
}

output "grafana_url" {
  description = "URL for the Grafana UI."
  value       = "http://localhost:${var.grafana_port}"
}

output "alertmanager_url" {
  description = "URL for the Alertmanager UI."
  value       = "http://localhost:${var.alertmanager_port}"
}

output "mailpit_url" {
  description = "URL for the Mailpit web interface."
  value       = "http://localhost:${var.mailpit_web_port}"
}
