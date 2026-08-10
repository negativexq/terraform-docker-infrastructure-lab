mock_provider "docker" {
}

run "observability_resources_follow_inputs" {
  command = plan

  module {
    source = "./modules/observability"
  }

  variables {
    environment             = "development"
    container_name_prefix   = "test-stack"
    network_name            = "test-stack-development-network"
    prometheus_config_dir   = "prometheus"
    alertmanager_config_dir = "alertmanager"
    grafana_config_dir      = "grafana"
    prometheus_image        = "prom/prometheus:test"
    prometheus_port         = 19090
    grafana_image           = "grafana/grafana:test"
    grafana_port            = 13000
    grafana_admin_password  = "test-grafana-password"
    alertmanager_image      = "prom/alertmanager:test"
    alertmanager_port       = 19093
    mailpit_image           = "axllent/mailpit:test"
    mailpit_web_port        = 18025
  }

  assert {
    condition     = resource.docker_image.prometheus.name == "prom/prometheus:test" && resource.docker_image.grafana.name == "grafana/grafana:test" && resource.docker_image.alertmanager.name == "prom/alertmanager:test" && resource.docker_image.mailpit.name == "axllent/mailpit:test"
    error_message = "Observability images must use their corresponding inputs."
  }

  assert {
    condition     = resource.docker_container.prometheus.name == "test-stack-development-prometheus" && resource.docker_container.grafana.name == "test-stack-development-grafana" && resource.docker_container.alertmanager.name == "test-stack-development-alertmanager" && resource.docker_container.mailpit.name == "test-stack-development-mailpit"
    error_message = "Observability container names must use the prefix and environment."
  }

  assert {
    condition     = one([for port in resource.docker_container.prometheus.ports : port.external]) == 19090 && one([for port in resource.docker_container.grafana.ports : port.external]) == 13000 && one([for port in resource.docker_container.alertmanager.ports : port.external]) == 19093 && one([for port in resource.docker_container.mailpit.ports : port.external]) == 18025
    error_message = "Observability host ports must use their corresponding inputs."
  }

  assert {
    condition     = contains(one([for network in resource.docker_container.prometheus.networks_advanced : network.aliases]), "prometheus") && contains(one([for network in resource.docker_container.alertmanager.networks_advanced : network.aliases]), "alertmanager") && contains(one([for network in resource.docker_container.mailpit.networks_advanced : network.aliases]), "mailpit") && one([for network in resource.docker_container.grafana.networks_advanced : network.name]) == "test-stack-development-network"
    error_message = "Observability containers must use the shared network and expected aliases."
  }

  assert {
    condition     = output.prometheus_url == "http://localhost:19090" && output.grafana_url == "http://localhost:13000" && output.alertmanager_url == "http://localhost:19093" && output.mailpit_url == "http://localhost:18025"
    error_message = "Observability URLs must use the configured host ports."
  }

  assert {
    condition     = resource.terraform_data.prometheus_config.input == sha256(join("", [for file in sort(tolist(fileset("prometheus", "**"))) : format("%s:%s", file, filesha256(format("prometheus/%s", file)))])) && resource.terraform_data.alertmanager_config.input == sha256(join("", [for file in sort(tolist(fileset("alertmanager", "**"))) : format("%s:%s", file, filesha256(format("alertmanager/%s", file)))])) && resource.terraform_data.grafana_config.input == sha256(join("", [for file in sort(tolist(fileset("grafana", "**"))) : format("%s:%s", file, filesha256(format("grafana/%s", file)))]))
    error_message = "Configuration hash inputs must remain tied to the configuration files."
  }
}
