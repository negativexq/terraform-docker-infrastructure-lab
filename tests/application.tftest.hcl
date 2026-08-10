mock_provider "docker" {
}

run "application_resources_follow_inputs" {
  command = plan

  module {
    source = "./modules/application"
  }

  variables {
    environment           = "production"
    container_name_prefix = "test-stack"
    network_name          = "test-stack-production-network"
    app_context           = "app"
    nginx_config_path     = "/tmp/terraform-test-nginx.conf"
    app_image             = "terraform-docker-lab-api:test"
    nginx_image           = "nginx:test"
    nginx_port            = 18081
    postgres_image        = "postgres:test"
    postgres_db           = "testdb"
    postgres_user         = "testuser"
    postgres_password     = "test-postgres-password"
  }

  assert {
    condition     = resource.docker_volume.postgres.name == "test-stack-production-postgres-data"
    error_message = "The PostgreSQL volume name must use the prefix and environment."
  }

  assert {
    condition     = resource.docker_image.postgres.name == "postgres:test" && resource.docker_image.app.name == "terraform-docker-lab-api:test" && resource.docker_image.nginx.name == "nginx:test"
    error_message = "The PostgreSQL, FastAPI, and Nginx images must use their inputs."
  }

  assert {
    condition     = resource.docker_container.postgres.name == "test-stack-production-postgres" && resource.docker_container.app.name == "test-stack-production-api" && resource.docker_container.nginx.name == "test-stack-production-nginx"
    error_message = "Application container names must use the prefix and environment."
  }

  assert {
    condition     = one([for network in resource.docker_container.postgres.networks_advanced : network.name]) == "test-stack-production-network" && one([for volume in resource.docker_container.postgres.volumes : volume.volume_name]) == "test-stack-production-postgres-data"
    error_message = "The PostgreSQL container must use the shared network and PostgreSQL volume."
  }

  assert {
    condition     = one([for port in resource.docker_container.nginx.ports : port.external]) == 18081
    error_message = "The Nginx host port must use the nginx_port input."
  }

  assert {
    condition     = one([for network in resource.docker_container.app.networks_advanced : network.name]) == "test-stack-production-network" && contains(one([for network in resource.docker_container.app.networks_advanced : network.aliases]), "api")
    error_message = "The FastAPI container must use the shared network and api alias."
  }

  assert {
    condition     = resource.docker_image.app.triggers.source_hash != ""
    error_message = "The FastAPI image must retain its application source hash trigger."
  }
}
