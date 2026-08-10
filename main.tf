locals {
  name = "${var.container_name_prefix}-${var.environment}"

  # Keep the build trigger deterministic: sort paths and hash both each path
  # and its content. Generated Python cache files are excluded because they
  # are already excluded from the Docker build context.
  app_source_files = sort([
    for file in fileset("${path.module}/app", "**") : file
    if !startswith(file, "__pycache__/") &&
    !startswith(file, ".pytest_cache/") &&
    !startswith(file, ".ruff_cache/") &&
    !endswith(file, ".pyc")
  ])
  app_source_hash = sha256(join("", [
    for file in local.app_source_files : "${file}:${filesha256("${path.module}/app/${file}")}"
  ]))
}

resource "docker_network" "app" {
  name = "${local.name}-network"
}

resource "docker_volume" "postgres" {
  name = "${local.name}-postgres-data"
}

resource "docker_image" "postgres" {
  name         = var.postgres_image
  keep_locally = true
}

resource "docker_image" "nginx" {
  name         = var.nginx_image
  keep_locally = true
}

resource "docker_image" "app" {
  name = var.app_image

  triggers = {
    source_hash = local.app_source_hash
  }

  build {
    context    = "${path.module}/app"
    dockerfile = "Dockerfile"
  }

  keep_locally = true
}

resource "docker_image" "prometheus" {
  name         = var.prometheus_image
  keep_locally = true
}

resource "docker_image" "grafana" {
  name         = var.grafana_image
  keep_locally = true
}

resource "docker_container" "postgres" {
  name  = "${local.name}-postgres"
  image = docker_image.postgres.image_id

  env = [
    "POSTGRES_DB=${var.postgres_db}",
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${var.postgres_password}",
  ]

  networks_advanced {
    name = docker_network.app.name
  }

  volumes {
    volume_name    = docker_volume.postgres.name
    container_path = "/var/lib/postgresql/data"
  }

  healthcheck {
    test         = ["CMD-SHELL", "pg_isready -U ${var.postgres_user} -d ${var.postgres_db}"]
    interval     = "5s"
    timeout      = "3s"
    retries      = 10
    start_period = "10s"
  }
}

resource "docker_container" "app" {
  name  = "${local.name}-api"
  image = docker_image.app.image_id

  env = [
    "APP_ENV=${var.environment}",
    "POSTGRES_HOST=${docker_container.postgres.name}",
    "POSTGRES_DB=${var.postgres_db}",
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${var.postgres_password}",
  ]

  networks_advanced {
    name    = docker_network.app.name
    aliases = ["api"]
  }

  healthcheck {
    test         = ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:8000/db-health', timeout=2)\""]
    interval     = "5s"
    timeout      = "3s"
    retries      = 10
    start_period = "15s"
  }

  depends_on = [docker_container.postgres]
}

resource "docker_container" "nginx" {
  name  = "${local.name}-nginx"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = var.nginx_port
  }

  networks_advanced {
    name = docker_network.app.name
  }

  volumes {
    host_path      = abspath("${path.module}/nginx/nginx.conf")
    container_path = "/etc/nginx/nginx.conf"
    read_only      = true
  }

  healthcheck {
    test         = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost/health || exit 1"]
    interval     = "5s"
    timeout      = "3s"
    retries      = 10
    start_period = "5s"
  }

  depends_on = [docker_container.app]
}

resource "docker_container" "prometheus" {
  name  = "${local.name}-prometheus"
  image = docker_image.prometheus.image_id

  ports {
    internal = 9090
    external = var.prometheus_port
  }

  networks_advanced {
    name    = docker_network.app.name
    aliases = ["prometheus"]
  }

  volumes {
    host_path      = abspath("${path.module}/prometheus/prometheus.yml")
    container_path = "/etc/prometheus/prometheus.yml"
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

  depends_on = [docker_container.app]
}

resource "docker_container" "grafana" {
  name  = "${local.name}-grafana"
  image = docker_image.grafana.image_id

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
    name = docker_network.app.name
  }

  volumes {
    host_path      = abspath("${path.module}/grafana/provisioning")
    container_path = "/etc/grafana/provisioning"
    read_only      = true
  }

  volumes {
    host_path      = abspath("${path.module}/grafana/dashboards")
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
