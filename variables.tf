variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "loc" {
  description = "Azure location."
  type        = string
  default     = "uksouth"
}

variable "loc_short" {
  description = "Azure location short name."
  type        = string
  default     = "uks"
}

variable "admin_username" {
  description = "Admin username for the VMs."
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Admin password for the VMs."
  type        = string
}

variable "active_directory_domain" {
  description = "Active Directory domain name."
  type        = string
  default     = "big.brain"
}

variable "create_bastion" {
  description = "Create Azure Bastion."
  type        = bool
  default     = true
}

variable "enable_nsgs" {
  description = "Enable or disable the creation of NSGs and their associations"
  type        = bool
  default     = true
}