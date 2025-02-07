terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "0.136.0"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

resource "yandex_vpc_network" "bookstore_network" {
  name = "bookstore-network20"
}

resource "yandex_vpc_subnet" "bookstore_subnet" {
  name           = "bookstore-subnet20"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.bookstore_network.id
  v4_cidr_blocks = ["192.168.1.0/24"]
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "private_key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.module}/id_rsa_bookstore"
}

resource "local_file" "public_key" {
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = "${path.module}/id_rsa_bookstore.pub"
}

resource "yandex_compute_instance" "bookstore_vm" {
  name        = "bookstore-vm20"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = "fd86idv7gmqapoeiq5ld"
      size     = 20
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.bookstore_subnet.id
    nat       = true
  }

  metadata = {
    user-data = <<-EOF
        #cloud-config
        users:
          - name: yc-user
            groups: sudo
            shell: /bin/bash
            sudo: ["ALL=(ALL) NOPASSWD:ALL"]
            ssh-authorized-keys:
              - ssh-rsa ${tls_private_key.ssh_key.public_key_openssh}
        EOF
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y docker.io",
      "sudo docker run -d -p 80:8080 --name bookstore jmix/jmix-bookstore"
    ]

    connection {
      type        = "ssh"
      host        = self.network_interface[0].nat_ip_address
      user        = "yc-user"
      private_key = tls_private_key.ssh_key.private_key_pem
    }
  }
}

output "ssh_connection_string" {
  value = "ssh -i ${path.module}/id_rsa_bookstore yc-user@${yandex_compute_instance.bookstore_vm.network_interface[0].nat_ip_address}"
}

output "web_app_url" {
  value = "http://${yandex_compute_instance.bookstore_vm.network_interface[0].nat_ip_address}"
}