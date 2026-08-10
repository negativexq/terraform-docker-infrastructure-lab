mock_provider "docker" {}

run "network_name_and_unique_ports" {
  command = plan

  module {
    source = "./modules/network"
  }

  variables {
    network_name = "test-production-network"
    host_ports   = [8081, 9091, 3001, 9094, 8026]
  }

  assert {
    condition     = resource.docker_network.app.name == "test-production-network"
    error_message = "The network name must come from the network_name input."
  }
}

run "duplicate_host_ports_are_rejected" {
  command = plan

  module {
    source = "./modules/network"
  }

  variables {
    network_name = "test-development-network"
    host_ports   = [8080, 9090, 3000, 9090, 8025]
  }

  expect_failures = [resource.docker_network.app]
}
