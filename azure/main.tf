# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "myResourceGroup"
    location = "eastus"

    tags = {
        environment = "Terraform Azure"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    tags = {
        environment = "Terraform Azure"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "eastus"
    resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"
    allocation_method            = "Static"

    tags = {
        environment = "Terraform Azure"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Azure"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "myNIC"
    location                  = "eastus"
    resource_group_name       = "${azurerm_resource_group.myterraformgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
    }

    tags = {
        environment = "Terraform Azure"
    }
}


# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diagrandom1"
    resource_group_name         = "${azurerm_resource_group.myterraformgroup.name}"
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Azure"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "myVM"
    location              = "eastus"
    resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myvm"
        admin_username = "azureuser"
	admin_password = "azureuser"
    }
    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "${file("~/.ssh/id_rsa.pub")}"
        }
    }
    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags = {
        environment = "Terraform Azure"
    }

}

resource "null_resource" "cluster" {

   connection {
                type = "ssh"
                user = "azureuser"
                host = "${azurerm_public_ip.myterraformpublicip.ip_address}"
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
   depends_on = ["azurerm_virtual_machine.myterraformvm"]
}


# Create public IPs 2
resource "azurerm_public_ip" "myterraformpublicip2" {
    name                         = "myPublicIP2"
    location                     = "eastus"
    resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"
    allocation_method            = "Static"

    tags = {
        environment = "Terraform Azure"
    }
}


# Create network interface 2
resource "azurerm_network_interface" "myterraformnic2" {
    name                      = "myNIC2"
    location                  = "eastus"
    resource_group_name       = "${azurerm_resource_group.myterraformgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration2"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip2.id}"
    }

    tags = {
        environment = "Terraform Azure"
    }
}


# Create virtual machine 2
resource "azurerm_virtual_machine" "myterraformvm2" {
    name                  = "myVM2"
    location              = "eastus"
    resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.myterraformnic2.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk2"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Redhat"
        offer     = "RHEL"
        sku       = "7-RAW"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myvm2"
        admin_username = "azureuser"
        admin_password = "azureuser"
    }
    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "${file("~/.ssh/id_rsa.pub")}"
        }
    }
    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags = {
        environment = "Terraform Azure"
    }

}



resource "null_resource" "cluster2" {

   connection {
                type = "ssh"
                user = "azureuser"
                host = "${azurerm_public_ip.myterraformpublicip2.ip_address}"
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
   depends_on = ["azurerm_virtual_machine.myterraformvm2"]
}

