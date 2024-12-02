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
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_path)}"
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
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_path)}"
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
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_path)}"
  }
}

# Ansible Inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tmpl",
    {
      frontend_public_ip  = google_compute_instance.frontend.network_interface[0].access_config[0].nat_ip
      frontend_private_ip = google_compute_instance.frontend.network_interface[0].network_ip
      backend_ip         = google_compute_instance.backend.network_interface[0].network_ip
      database_ip        = google_compute_instance.database.network_interface[0].network_ip
      ssh_user          = var.ssh_user
    }
  )
  filename = "../ansible/inventories/gcp.yml"
}