resource "docker_network" "app" {
  name = var.network_name

  lifecycle {
    precondition {
      condition     = length(toset(var.host_ports)) == length(var.host_ports)
      error_message = "All application, monitoring and mail web host ports must be different."
    }
  }
}
