output "application_url" {
  description = "URL served by the Nginx reverse proxy."
  value       = module.application.application_url
}

output "network_name" {
  description = "Docker network used by all application services."
  value       = module.network.network_name
}

output "postgres_volume_name" {
  description = "Persistent Docker volume used by PostgreSQL."
  value       = module.application.postgres_volume_name
}

output "prometheus_url" {
  description = "URL for the Prometheus UI."
  value       = module.observability.prometheus_url
}

output "grafana_url" {
  description = "URL for the Grafana UI."
  value       = module.observability.grafana_url
}

output "alertmanager_url" {
  description = "URL for the Alertmanager UI."
  value       = module.observability.alertmanager_url
}

output "mailpit_url" {
  description = "URL for the Mailpit web interface."
  value       = module.observability.mailpit_url
}
