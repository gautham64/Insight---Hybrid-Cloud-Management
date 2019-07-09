provider "google" {
 credentials = "${file("My First Project-20bd4985f58d.json")}"
 project     = "canvas-cursor-244720"
 region      = "us-west1"
}

resource "google_compute_instance" "default" {
 name         = "ssminstance-gcp-1"
 machine_type = "f1-micro"
 zone         = "us-west1-a"

 boot_disk {
   initialize_params {
     image = "ubuntu-os-cloud/ubuntu-1604-lts"
   }
 }
 network_interface {
   network = "default"

   access_config {
     // Include this section to give the VM an external ip address
   }
 }
  tags = ["ssh-server"]

  metadata {
    sshKeys = "gcpuser:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "google_compute_firewall" "ssh-server" {
  name    = "default-allow-ssh-1"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  // Allow traffic from everywhere to instances with an http-server tag
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-server"]
}

resource "google_compute_instance" "default2" {
 name         = "ssminstance-gcp-2"
 machine_type = "f1-micro"
 zone         = "us-west1-a"

 boot_disk {
   initialize_params {
     image = "rhel-cloud/rhel-7"
   }
 }
 network_interface {
   network = "default"

   access_config {
     // Include this section to give the VM an external ip address
   }
 }
  tags = ["ssh-server"]

  metadata {
    sshKeys = "gcpuser:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "null_resource" "cluster" {

   connection {
                type = "ssh"
                user = "gcpuser"
                host = "${google_compute_instance.default.network_interface.0.access_config.0.nat_ip}"
                private_key = "${file("~/.ssh/id_rsa")}"
    }

    provisioner "file" {
        source = "user_data_ubuntu.sh"
        destination = "/tmp/user_data_ubuntu.sh"
    }
    provisioner "file" {
        source = "config"
        destination = "/tmp/config"
    }
    provisioner "file" {
        source = "aws_credentials"
        destination = "/tmp/aws_credentials"
    }

    provisioner "remote-exec" {

        inline = [
                "sudo chmod +x /tmp/user_data_ubuntu.sh",
                "cd /tmp",
                "sudo ./user_data_ubuntu.sh"
        ]
    }
}


resource "null_resource" "cluster2" {

   connection {
                type = "ssh"
                user = "gcpuser"
                host = "${google_compute_instance.default2.network_interface.0.access_config.0.nat_ip}"
                private_key = "${file("~/.ssh/id_rsa")}"
    }

    provisioner "file" {
        source = "user_data_rhel.sh"
        destination = "/tmp/user_data_rhel.sh"
    }
    provisioner "file" {
        source = "config"
        destination = "/tmp/config"
    }
    provisioner "file" {
        source = "aws_credentials"
        destination = "/tmp/aws_credentials"
    }

    provisioner "remote-exec" {

        inline = [
                "sudo chmod +x /tmp/user_data_rhel.sh",
                "cd /tmp",
                "sudo ./user_data_rhel.sh"
        ]
    }
}

