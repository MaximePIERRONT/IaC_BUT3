variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "upec-but3-cloud"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "tp-cloud"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "europe-west1-b"
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "e2-micro"
}

variable "frontend_cidr" {
  description = "CIDR for frontend subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "backend_cidr" {
  description = "CIDR for backend subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "database_cidr" {
  description = "CIDR for database subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "ssh_source_ranges" {
  description = "Source IP ranges for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

# variable "ssh_user" {
#   description = "SSH user for instances"
#   type        = string
#   default     = "admin"
# }
#
# variable "ssh_pub_key_path" {
#   description = "Path to SSH public key file"
#   type        = string
#   default     = "~/.ssh/id_rsa.pub"
# }