mock_provider "docker" {
}

run "development_outputs_and_names" {
  command = plan

  variables {
    environment            = "development"
    container_name_prefix  = "test-dev"
    nginx_port             = 18080
    prometheus_port        = 19090
    grafana_port           = 13000
    alertmanager_port      = 19093
    mailpit_web_port       = 18025
    postgres_password      = "test-postgres-password"
    grafana_admin_password = "test-grafana-password"
  }

  assert {
    condition     = output.application_url == "http://localhost:18080" && output.prometheus_url == "http://localhost:19090" && output.grafana_url == "http://localhost:13000" && output.alertmanager_url == "http://localhost:19093" && output.mailpit_url == "http://localhost:18025"
    error_message = "Development URLs must use all configured host ports."
  }

  assert {
    condition     = output.network_name == "test-dev-development-network" && output.postgres_volume_name == "test-dev-development-postgres-data"
    error_message = "Development network and PostgreSQL volume names must use the prefix and environment."
  }
}

run "production_outputs_and_names" {
  command = plan

  variables {
    environment            = "production"
    container_name_prefix  = "test-prod"
    nginx_port             = 18081
    prometheus_port        = 19091
    grafana_port           = 13001
    alertmanager_port      = 19094
    mailpit_web_port       = 18026
    postgres_password      = "test-postgres-password"
    grafana_admin_password = "test-grafana-password"
  }

  assert {
    condition     = output.application_url == "http://localhost:18081" && output.prometheus_url == "http://localhost:19091" && output.grafana_url == "http://localhost:13001" && output.alertmanager_url == "http://localhost:19094" && output.mailpit_url == "http://localhost:18026"
    error_message = "Production URLs must use all configured host ports."
  }

  assert {
    condition     = output.network_name == "test-prod-production-network" && output.postgres_volume_name == "test-prod-production-postgres-data"
    error_message = "Production network and PostgreSQL volume names must use the prefix and environment."
  }
}
