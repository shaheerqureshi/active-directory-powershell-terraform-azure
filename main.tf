terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }
}


provider "azurerm" {
  subscription_id = "b3420f2a-e375-45c7-8053-5478758ec8a6"
  features {}
}

#creating a resouce group
resource "azurerm_resource_group" "rg-dc" {
  name = var.resource_group_name
  location = var.location
}

#creating Vnet
resource "azurerm_virtual_network" "vnet-hub" {
  name = "vnet-dc"
  resource_group_name = azurerm_resource_group.rg-dc.name
  location = azurerm_resource_group.rg-dc.location
  address_space = [ "10.0.0.0/16" ]

  tags = {
    environment = "Production"
  }
}
resource "azurerm_subnet" "sn-dev" {
  name             = "sn-dev"
  resource_group_name = azurerm_resource_group.rg-dc.name
  virtual_network_name = azurerm_virtual_network.vnet-hub.name
  address_prefixes = ["10.0.1.0/24"]
}
resource "azurerm_subnet" "sn-prod" {
  name             = "sn-prod"
  resource_group_name = azurerm_resource_group.rg-dc.name
  virtual_network_name = azurerm_virtual_network.vnet-hub.name
  
  address_prefixes = ["10.0.2.0/24"]
}

#creating security group
resource "azurerm_network_security_group" "NSG-RDP" {
  name = "NSG-RDP"
  location = azurerm_resource_group.rg-dc.location
  resource_group_name = azurerm_resource_group.rg-dc.name

  security_rule {
    name = "Allow-RDP"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "3389"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-RDP-assoc" {
  subnet_id = azurerm_subnet.sn-prod.id
  network_security_group_id = azurerm_network_security_group.NSG-RDP.id
}

resource "azurerm_public_ip" "pip-adDC" {
  name = "pip-adDC-lab"
  resource_group_name = azurerm_resource_group.rg-dc.name
  location = azurerm_resource_group.rg-dc.location
  allocation_method = "Static"
  sku = "Standard"
}

resource "azurerm_network_interface" "adDC-nic" {
  name = "nic-adDC"
  resource_group_name = azurerm_resource_group.rg-dc.name
  location = azurerm_resource_group.rg-dc.location

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.sn-prod.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pip-adDC.id
  }
}
resource "azurerm_windows_virtual_machine" "vm-dc" {
  name                  = "vm-dc"
  resource_group_name   = azurerm_resource_group.rg-dc.name
  location              = azurerm_resource_group.rg-dc.location
  size                  = "Standard_B2ats_v2"
  admin_username        = "shaheeradmin"
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.adDC-nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}



