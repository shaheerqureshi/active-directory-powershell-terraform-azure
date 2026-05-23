variable "resource_group_name" {
  default = "rg-dc"
}

variable "location" {
  default = "canadacentral"
}

variable "admin_password" {
  sensitive = true
}

variable "my_ip" {
  description = "Your home public IP for NSG rules"
}