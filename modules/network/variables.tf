variable "network_name" {
  description = "Name of the shared Docker network."
  type        = string
}

variable "host_ports" {
  description = "Host ports that must be unique across the local stack."
  type        = list(number)

  validation {
    condition     = alltrue([for port in var.host_ports : port >= 1024 && port <= 65535])
    error_message = "All host ports must be between 1024 and 65535."
  }
}
