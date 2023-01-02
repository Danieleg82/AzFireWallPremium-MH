variable "resource_group_name" {
  default       = "AzFirewallPremiumTest"
}

variable "resource_group_location" {
  default = "westeurope"
}

variable "VNET_address_space" {
  default = "10.0.0.0/16"
}

variable "VMSubnet_address_range" {
  default = "10.0.1.0/24"
}

variable "AzFWSubnet_address_range" {
  default = "10.0.2.0/24"
}

variable "BastionVNETRange" {
  default = "10.0.3.0/24"
}

variable "AppGWSubnetRange" {
  default = "10.0.4.0/24"
}

