locals {
  name = "${var.container_name_prefix}-${var.environment}"

  prometheus_config_files = sort(tolist(fileset(var.prometheus_config_dir, "**")))
  prometheus_config_hash = sha256(join("", [
    for file in local.prometheus_config_files : "${file}:${filesha256("${var.prometheus_config_dir}/${file}")}"
  ]))

  alertmanager_config_files = sort(tolist(fileset(var.alertmanager_config_dir, "**")))
  alertmanager_config_hash = sha256(join("", [
    for file in local.alertmanager_config_files : "${file}:${filesha256("${var.alertmanager_config_dir}/${file}")}"
  ]))

  grafana_config_files = sort(tolist(fileset(var.grafana_config_dir, "**")))
  grafana_config_hash = sha256(join("", [
    for file in local.grafana_config_files : "${file}:${filesha256("${var.grafana_config_dir}/${file}")}"
  ]))
}

resource "docker_image" "prometheus" {
  name         = var.prometheus_image
  keep_locally = true
}

resource "docker_image" "grafana" {
  name         = var.grafana_image
  keep_locally = true
}

resource "docker_image" "alertmanager" {
  name         = var.alertmanager_image
  keep_locally = true
}

resource "docker_image" "mailpit" {
  name         = var.mailpit_image
  keep_locally = true
}

resource "terraform_data" "prometheus_config" {
  input = local.prometheus_config_hash
}

resource "terraform_data" "alertmanager_config" {
  input = local.alertmanager_config_hash
}

resource "terraform_data" "grafana_config" {
  input = local.grafana_config_hash
}

resource "docker_container" "prometheus" {
  name  = "${local.name}-prometheus"
  image = docker_image.prometheus.image_id

  lifecycle {
    replace_triggered_by = [terraform_data.prometheus_config]
  }

  ports {
    internal = 9090
    external = var.prometheus_port
  }

  networks_advanced {
    name    = var.network_name
    aliases = ["prometheus"]
  }

  volumes {
    host_path      = abspath("${var.prometheus_config_dir}/prometheus.yml")
    container_path = "/etc/prometheus/prometheus.yml"
    read_only      = true
  }

  volumes {
    host_path      = abspath("${var.prometheus_config_dir}/rules")
    container_path = "/etc/prometheus/rules"
    read_only      = true
  }

  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.path=/prometheus",
  ]

  healthcheck {
    test         = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:9090/-/healthy || exit 1"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 10
    start_period = "10s"
  }

  depends_on = [docker_container.alertmanager]
}

resource "docker_container" "grafana" {
  name  = "${local.name}-grafana"
  image = docker_image.grafana.image_id

  lifecycle {
    replace_triggered_by = [terraform_data.grafana_config]
  }

  ports {
    internal = 3000
    external = var.grafana_port
  }

  env = [
    "GF_SECURITY_ADMIN_USER=admin",
    "GF_SECURITY_ADMIN_PASSWORD=${var.grafana_admin_password}",
    "GF_USERS_ALLOW_SIGN_UP=false",
  ]

  networks_advanced {
    name = var.network_name
  }

  volumes {
    host_path      = abspath("${var.grafana_config_dir}/provisioning")
    container_path = "/etc/grafana/provisioning"
    read_only      = true
  }

  volumes {
    host_path      = abspath("${var.grafana_config_dir}/dashboards")
    container_path = "/var/lib/grafana/dashboards"
    read_only      = true
  }

  healthcheck {
    test         = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 10
    start_period = "15s"
  }

  depends_on = [docker_container.prometheus]
}

resource "docker_container" "alertmanager" {
  name  = "${local.name}-alertmanager"
  image = docker_image.alertmanager.image_id

  lifecycle {
    replace_triggered_by = [terraform_data.alertmanager_config]
  }

  ports {
    internal = 9093
    external = var.alertmanager_port
  }

  networks_advanced {
    name    = var.network_name
    aliases = ["alertmanager"]
  }

  volumes {
    host_path      = abspath("${var.alertmanager_config_dir}/alertmanager.yml")
    container_path = "/etc/alertmanager/alertmanager.yml"
    read_only      = true
  }

  command = [
    "--config.file=/etc/alertmanager/alertmanager.yml",
    "--storage.path=/alertmanager",
  ]

  healthcheck {
    test         = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:9093/-/healthy || exit 1"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 10
    start_period = "10s"
  }

  depends_on = [docker_container.mailpit]
}

resource "docker_container" "mailpit" {
  name  = "${local.name}-mailpit"
  image = docker_image.mailpit.image_id

  ports {
    internal = 8025
    external = var.mailpit_web_port
  }

  networks_advanced {
    name    = var.network_name
    aliases = ["mailpit"]
  }

  healthcheck {
    test           = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:8025/livez || exit 1"]
    interval       = "10s"
    timeout        = "5s"
    retries        = 10
    start_period   = "5s"
    start_interval = "1s"
  }
}
