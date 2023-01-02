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

data "azurerm_resource_group" "RG" {
  name     = var.resource_group_name
}

data "azurerm_virtual_network" "VNET" {
  name                = "VNET1"
  resource_group_name = data.azurerm_resource_group.RG.name
}

data "azurerm_firewall" "AzFW" {
name                = "AzFW"
resource_group_name = data.azurerm_resource_group.RG.name
}

resource "azurerm_subnet" "AppGWSubnet" {
  name                 = "AppGWSubnet"
  resource_group_name  =  data.azurerm_resource_group.RG.name
  virtual_network_name =  data.azurerm_virtual_network.VNET.name
  address_prefixes     = ["${var.AppGWSubnetRange}"]
}

resource "azurerm_public_ip" "AppGWVIP" {
  name                = "MyAppGWVIP"
  sku                 = "Standard"
  resource_group_name = data.azurerm_resource_group.RG.name
  location            = data.azurerm_resource_group.RG.location
  allocation_method   = "Static"
}

resource "azurerm_application_gateway" "AppGW" {
  name                = "AppGW"
  resource_group_name = data.azurerm_resource_group.RG.name
  location            = data.azurerm_resource_group.RG.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.AppGWSubnet.id
  }

  frontend_port {
    name = "HTTPport"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "my-gateway-frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.AppGWVIP.id
  }

  backend_address_pool {
    name = "BackendPool1"
    ip_addresses = ["10.0.1.5"]
  }

  probe {
    name = "MyProbe"
    protocol = "Https"
    path = "/"
    interval = 2
    timeout = 5
    unhealthy_threshold = 2
    host = "MyprotectedApp.AzFWMH.net"

  }

  backend_http_settings {
    name                  = "HTTPSsetting"
    probe_name            = "MyProbe"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60
  }

  http_listener {
    name                           = "Listener1"
    frontend_ip_configuration_name = "my-gateway-frontend-ip-configuration"
    frontend_port_name             = "HTTPSport"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "Rule1"
    rule_type                  = "Basic"
    http_listener_name         = "Listener1"
    backend_address_pool_name  = "BackendPool1"
    backend_http_settings_name = "HTTPSsetting"
  }

  waf_configuration {
    enabled                    = true
    firewall_mode              = "Prevention"
    rule_set_version           = "3.2"
  }
}

resource "azurerm_route_table" "APPGWUDR" {
  name                          = "APPGWUDR"
  location                      = data.azurerm_resource_group.RG.location
  resource_group_name           = data.azurerm_resource_group.RG.name
  disable_bgp_route_propagation = false

  route {
    name           = "route1"
    address_prefix = "10.0.1.0/24"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = data.azurerm_firewall.AzFW.ip_configuration[0].private_ip_address
  }  
}

resource "azurerm_subnet_route_table_association" "APPGWUDRSubnetassociation" {
  subnet_id      = azurerm_subnet.AppGWSubnet.id
  route_table_id = azurerm_route_table.APPGWUDR.id
}