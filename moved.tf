moved {
  from = docker_network.app
  to   = module.network.docker_network.app
}

moved {
  from = docker_volume.postgres
  to   = module.application.docker_volume.postgres
}

moved {
  from = docker_image.postgres
  to   = module.application.docker_image.postgres
}

moved {
  from = docker_image.nginx
  to   = module.application.docker_image.nginx
}

moved {
  from = docker_image.app
  to   = module.application.docker_image.app
}

moved {
  from = docker_container.postgres
  to   = module.application.docker_container.postgres
}

moved {
  from = docker_container.app
  to   = module.application.docker_container.app
}

moved {
  from = docker_container.nginx
  to   = module.application.docker_container.nginx
}

moved {
  from = docker_image.prometheus
  to   = module.observability.docker_image.prometheus
}

moved {
  from = docker_image.grafana
  to   = module.observability.docker_image.grafana
}

moved {
  from = docker_image.alertmanager
  to   = module.observability.docker_image.alertmanager
}

moved {
  from = docker_image.mailpit
  to   = module.observability.docker_image.mailpit
}

moved {
  from = terraform_data.prometheus_config
  to   = module.observability.terraform_data.prometheus_config
}

moved {
  from = terraform_data.alertmanager_config
  to   = module.observability.terraform_data.alertmanager_config
}

moved {
  from = terraform_data.grafana_config
  to   = module.observability.terraform_data.grafana_config
}

moved {
  from = docker_container.prometheus
  to   = module.observability.docker_container.prometheus
}

moved {
  from = docker_container.grafana
  to   = module.observability.docker_container.grafana
}

moved {
  from = docker_container.alertmanager
  to   = module.observability.docker_container.alertmanager
}

moved {
  from = docker_container.mailpit
  to   = module.observability.docker_container.mailpit
}
