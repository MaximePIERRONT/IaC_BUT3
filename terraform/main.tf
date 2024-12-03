terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Network
resource "google_compute_network" "vpc" {
  name                    = "${var.project_name}-network"
  auto_create_subnetworks = false
}

# Subnets
resource "google_compute_subnetwork" "frontend" {
  name          = "frontend-subnet"
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.frontend_cidr
  region        = var.region
}

resource "google_compute_subnetwork" "backend" {
  name          = "backend-subnet"
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.backend_cidr
  region        = var.region
}

resource "google_compute_subnetwork" "database" {
  name          = "database-subnet"
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.database_cidr
  region        = var.region
}

# Firewall Rules
resource "google_compute_firewall" "allow_web" {
  name    = "allow-web"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["frontend"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.ssh_source_ranges]
  target_tags   = ["frontend", "backend", "database"]
}

resource "google_compute_firewall" "allow_frontend_to_backend" {
  name    = "allow-frontend-to-backend"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }

  source_tags = ["frontend"]
  target_tags = ["backend"]
}

resource "google_compute_firewall" "allow_backend_to_db" {
  name    = "allow-backend-to-db"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_tags = ["backend"]
  target_tags = ["database"]
}

# Compute Instances
resource "google_compute_instance" "frontend" {
  name         = "frontend"
  machine_type = var.instance_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.frontend.id
    access_config {} # Public IP
  }

  tags = ["frontend", "ssh"]

  metadata = {
    enable-oslogin = "TRUE"
  }
}

resource "google_compute_instance" "backend" {
  name         = "backend"
  machine_type = var.instance_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.backend.id
  }

  tags = ["backend", "ssh"]

  metadata = {
    enable-oslogin = "TRUE"
  }
}

resource "google_compute_instance" "database" {
  name         = "database"
  machine_type = var.instance_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20  # Plus grand pour la DB
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.database.id
  }

  tags = ["database", "ssh"]

  metadata = {
    enable-oslogin = "TRUE"
  }
}

# # Ansible Inventory
# resource "local_file" "ansible_inventory" {
#   content = templatefile("${path.module}/templates/inventory.tmpl",
#     {
#       frontend_public_ip  = google_compute_instance.frontend.network_interface[0].access_config[0].nat_ip
#       frontend_private_ip = google_compute_instance.frontend.network_interface[0].network_ip
#       backend_ip         = google_compute_instance.backend.network_interface[0].network_ip
#       database_ip        = google_compute_instance.database.network_interface[0].network_ip
#       ssh_user          = var.ssh_user
#     }
#   )
#   filename = "../ansible/inventories/gcp.yml"
# }

resource "google_service_account" "service_account" {
  account_id   = "terraform"
  display_name = "terraform"
}

resource "google_service_account_key" "service_account" {
  service_account_id = google_service_account.service_account.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "local_file" "service_account" {
  content  = base64decode(google_service_account_key.service_account.private_key)
  filename = "../ansible/service_account.json"
}

# Modification du compte de service existant
resource "google_project_iam_binding" "service_account_roles" {
  project = var.project_id
  role    = "roles/viewer"
  members = ["serviceAccount:${google_service_account.service_account.email}"]
}

data "google_client_openid_userinfo" "me" {
}

resource "google_os_login_ssh_public_key" "add_my_key" {
  project = var.project_id
  user =  data.google_client_openid_userinfo.me.email
  key = file("~/.ssh/id_ed25519.pub")
}


# # Récupération des infos utilisateur
#
# resource "null_resource" "ssh_directory" {
#   provisioner "local-exec" {
#     command = "mkdir -p ../ansible/ssh"
#   }
# }
#
# # Génération de la clé SSH
# resource "tls_private_key" "ssh" {
#   algorithm = "ED25519"
# }
#
# resource "local_file" "private_key" {
#   depends_on = [null_resource.ssh_directory]
#   content    = tls_private_key.ssh.private_key_openssh
#   filename   = "../ansible/ssh/id_ed25519"
#   file_permission = "0600"
# }
#
# resource "local_file" "public_key" {
#   depends_on = [null_resource.ssh_directory]
#   content    = tls_private_key.ssh.public_key_openssh
#   filename   = "../ansible/ssh/id_ed25519.pub"
#   file_permission = "0644"
# }
#



