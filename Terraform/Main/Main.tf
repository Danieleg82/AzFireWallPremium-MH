terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "RG" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_virtual_network" "VNET" {
  name                = "VNET1"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  address_space       = ["${var.VNET_address_space}"]
}

resource "azurerm_subnet" "VMSubnet" {
  name                 = "Subnet1"
  resource_group_name  =  azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes     = ["${var.VMSubnet_address_range}"]
}

resource "azurerm_subnet" "AzFWSubnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes     = ["${var.AzFWSubnet_address_range}"]
}

resource "azurerm_firewall_policy" "AzFWPolicy" {
  name                = "AzFWPolicy"
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location
  sku                 = "Premium"
}

resource "azurerm_public_ip" "AzFWPIP" {
  name                = "AzFWPIP"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "AzFW" {
  name                = "AzFW"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Premium"
  firewall_policy_id =  azurerm_firewall_policy.AzFWPolicy.id

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.AzFWSubnet.id
    public_ip_address_id = azurerm_public_ip.AzFWPIP.id
  }
}

resource "azurerm_route_table" "VMUDR" {
  name                          = "VMUDR"
  location                      = azurerm_resource_group.RG.location
  resource_group_name           = azurerm_resource_group.RG.name
  disable_bgp_route_propagation = false

  route {
    name           = "route1"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.AzFW.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "UDRSubnetassociation" {
  subnet_id      = azurerm_subnet.VMSubnet.id
  route_table_id = azurerm_route_table.VMUDR.id
}

resource "azurerm_network_interface" "VMNic" {
  name                = "VMNIC"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.VMSubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "VM1" {
  name                = "VM1"
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"
  admin_password      = "AzFWPa$$w0rd"
  network_interface_ids = [
    azurerm_network_interface.VMNic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

 source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

#Creating Bastion to access VM

resource "azurerm_subnet" "BastionSubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes     = ["${var.BastionVNETRange}"]
}

resource "azurerm_public_ip" "BastionVIP" {
  name                = "BastionVIP"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "BastionHost" {
  name                = "BastionHost"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  sku                 = "Standard"
  file_copy_enabled   = true
  tunneling_enabled   = true

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.BastionSubnet.id
    public_ip_address_id = azurerm_public_ip.BastionVIP.id
  }
}
