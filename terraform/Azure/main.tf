# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {

  features {}
}

# Create a resource group
resource "azurerm_resource_group" "tform-rg" {
  name     = "tform-resources"
  location = "East US"
  tags = {
    envirnment = "dev"
  }
}

# Create a vnet
resource "azurerm_virtual_network" "tform-vn" {
  name                = "tform-network"
  resource_group_name = azurerm_resource_group.tform-rg.name
  location            = azurerm_resource_group.tform-rg.location
  address_space       = ["10.123.0.0/16"]

  tags = {
    environment = "dev"
  }
}


# Create a subnet
resource "azurerm_subnet" "tform-subnet" {
  name                 = "tform-subnet-1"
  resource_group_name  = azurerm_resource_group.tform-rg.name
  virtual_network_name = azurerm_virtual_network.tform-vn.name
  address_prefixes     = ["10.123.1.0/24"]
}


# Create a security group
resource "azurerm_network_security_group" "tform-sg" {
  name                = "tform-sec-group"
  location            = azurerm_resource_group.tform-rg.location
  resource_group_name = azurerm_resource_group.tform-rg.name

  tags = {
    envirnment = "dev"
  }
}

# Create a securuty rule
resource "azurerm_network_security_rule" "tform-dev-rule" {
  name                        = "tform-dev-sec-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.tform-rg.name
  network_security_group_name = azurerm_network_security_group.tform-sg.name
}


# Create a security group association
resource "azurerm_subnet_network_security_group_association" "tform-sg-assoc" {
  subnet_id                 = azurerm_subnet.tform-subnet.id
  network_security_group_id = azurerm_network_security_group.tform-sg.id
}

# Create a public ip
resource "azurerm_public_ip" "tform-pip" {
  name                = "tform-pip1"
  resource_group_name = azurerm_resource_group.tform-rg.name
  location            = azurerm_resource_group.tform-rg.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "Dev"
  }
}

# Create a nic
resource "azurerm_network_interface" "tform-nic" {
  name                = "tform-nic"
  location            = azurerm_resource_group.tform-rg.location
  resource_group_name = azurerm_resource_group.tform-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.tform-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tform-pip.id
  }
  tags = {
    environment = "Dev"
  }

}

# Create a vm
resource "azurerm_linux_virtual_machine" "tform-vm" {
  name                = "tform-machine"
  resource_group_name = azurerm_resource_group.tform-rg.name
  location            = azurerm_resource_group.tform-rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.tform-nic.id,
  ]

  # Add a custom data source to install Docker and its dependencies
  custom_data = filebase64("customdata.tpl")

  # Add SSH key
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/tformkey.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # Add SSH access to VS Code 
  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-script.tpl", { # specified in terraform.tfvars
      hostname     = self.public_ip_address,
      user         = "adminuser",
      identityfile = "~/.ssh/tformkey"
    })
    interpreter = var.host_os == "mac" ? ["bash", "-c"] : ["zsh", "-c"]
  }

  tags = {
    environment = "dev"
  }
}

# Add a data source to pull public IP
data "azurerm_public_ip" "tform-pip-data" {
  name                = azurerm_public_ip.tform-pip.name
  resource_group_name = azurerm_resource_group.tform-rg.name
}

# Add output
output "public_ip_address" {
  value = "${azurerm_linux_virtual_machine.tform-vm.name}:${data.azurerm_public_ip.tform-pip-data.ip_address}"
}
