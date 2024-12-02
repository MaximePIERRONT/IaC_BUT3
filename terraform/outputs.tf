output "vpc_id" {
  description = "ID of the VPC"
  value       = google_compute_network.vpc.id
}

output "subnet_ids" {
  description = "IDs of all subnets"
  value = {
    frontend = google_compute_subnetwork.frontend.id
    backend  = google_compute_subnetwork.backend.id
    database = google_compute_subnetwork.database.id
  }
}

output "frontend_public_ip" {
  description = "Public IP of frontend instance"
  value       = google_compute_instance.frontend.network_interface[0].access_config[0].nat_ip
}

output "instance_internal_ips" {
  description = "Internal IPs of all instances"
  value = {
    frontend = google_compute_instance.frontend.network_interface[0].network_ip
    backend  = google_compute_instance.backend.network_interface[0].network_ip
    database = google_compute_instance.database.network_interface[0].network_ip
  }
}

output "instance_names" {
  description = "Names of all instances"
  value = {
    frontend = google_compute_instance.frontend.name
    backend  = google_compute_instance.backend.name
    database = google_compute_instance.database.name
  }
}

output "connection_command" {
  description = "Command to connect to frontend instance"
  value       = "ssh ${var.ssh_user}@${google_compute_instance.frontend.network_interface[0].access_config[0].nat_ip}"
}