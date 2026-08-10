output "network_name" {
  description = "Name of the shared Docker network."
  value       = docker_network.app.name
}
