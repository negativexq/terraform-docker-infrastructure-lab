module "network" {
  source = "./modules/network"

  network_name = "${var.container_name_prefix}-${var.environment}-network"
  host_ports = [
    var.nginx_port,
    var.prometheus_port,
    var.grafana_port,
    var.alertmanager_port,
    var.mailpit_web_port,
  ]
}

module "application" {
  source = "./modules/application"

  environment           = var.environment
  container_name_prefix = var.container_name_prefix
  network_name          = module.network.network_name

  app_context       = "./app"
  nginx_config_path = abspath("${path.root}/nginx/nginx.conf")
  app_image         = var.app_image
  nginx_image       = var.nginx_image
  nginx_port        = var.nginx_port
  postgres_db       = var.postgres_db
  postgres_image    = var.postgres_image
  postgres_password = var.postgres_password
  postgres_user     = var.postgres_user
}

module "observability" {
  source = "./modules/observability"

  environment           = var.environment
  container_name_prefix = var.container_name_prefix
  network_name          = module.network.network_name

  prometheus_config_dir   = abspath("${path.root}/prometheus")
  alertmanager_config_dir = abspath("${path.root}/alertmanager")
  grafana_config_dir      = abspath("${path.root}/grafana")

  prometheus_image       = var.prometheus_image
  prometheus_port        = var.prometheus_port
  grafana_image          = var.grafana_image
  grafana_port           = var.grafana_port
  grafana_admin_password = var.grafana_admin_password
  alertmanager_image     = var.alertmanager_image
  alertmanager_port      = var.alertmanager_port
  mailpit_image          = var.mailpit_image
  mailpit_web_port       = var.mailpit_web_port

  depends_on = [module.application]
}
