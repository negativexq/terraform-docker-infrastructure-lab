locals {
  name             = "${var.container_name_prefix}-${var.environment}"
  app_context_path = abspath("${path.root}/${var.app_context}")

  # Sort paths and include each path with its content hash for a stable
  # trigger. Generated cache files are excluded from the Docker context.
  app_source_files = sort([
    for file in fileset(local.app_context_path, "**") : file
    if !startswith(file, "__pycache__/") &&
    !startswith(file, ".pytest_cache/") &&
    !startswith(file, ".ruff_cache/") &&
    !endswith(file, ".pyc")
  ])
  app_source_hash = sha256(join("", [
    for file in local.app_source_files : "${file}:${filesha256("${local.app_context_path}/${file}")}"
  ]))
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
    context    = var.app_context
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
    name = var.network_name
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

  env = concat([
    "APP_ENV=${var.environment}",
    "POSTGRES_HOST=${docker_container.postgres.name}",
    "POSTGRES_DB=${var.postgres_db}",
    "POSTGRES_USER=${var.postgres_user}",
    "POSTGRES_PASSWORD=${var.postgres_password}",
  ], var.enable_test_endpoints ? ["ENABLE_TEST_ENDPOINTS=true"] : [])

  networks_advanced {
    name    = var.network_name
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
    name = var.network_name
  }

  volumes {
    host_path      = var.nginx_config_path
    container_path = "/etc/nginx/nginx.conf"
    read_only      = true
  }

  healthcheck {
    test         = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://127.0.0.1/health || exit 1"]
    interval     = "5s"
    timeout      = "3s"
    retries      = 10
    start_period = "5s"
  }

  depends_on = [docker_container.app]
}
