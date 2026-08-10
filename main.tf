locals {
  name = "${var.container_name_prefix}-${var.environment}"
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

  build {
    context    = "${path.module}/app"
    dockerfile = "Dockerfile"
  }

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
