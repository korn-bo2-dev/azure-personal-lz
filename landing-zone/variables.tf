variable "subscription_id" {
  description = "The Azure subscription that hosts the landing zone."
  type        = string
}

variable "location" {
  description = "Primary Azure region."
  type        = string
  default     = "australiaeast"
}

variable "name_suffix" {
  description = "Short unique suffix for globally unique names (lowercase letters/digits, 3-6 chars)."
  type        = string
}

variable "budget_amount" {
  description = "Monthly budget for the subscription, in the billing currency."
  type        = number
  default     = 30
}

variable "budget_contact_emails" {
  description = "Who gets budget alerts."
  type        = list(string)
}

variable "address_space" {
  description = "VNet address space."
  type        = string
  default     = "10.10.0.0/16"
}

variable "vm_size" {
  description = "VM size. Standard_B1s is covered by the 12-month free account offer."
  type        = string
  default     = "Standard_B1s"
}

variable "vm_admin_username" {
  type    = string
  default = "azureuser"
}

variable "vm_admin_ssh_public_key" {
  description = "Your SSH public key (the .pub file contents). Never the private key."
  type        = string
}

variable "vm_auto_shutdown_time" {
  description = "Daily auto-shutdown time (HHmm) to save cost."
  type        = string
  default     = "2300"
}

variable "timezone" {
  type    = string
  default = "AUS Eastern Standard Time"
}

variable "sql_admin_login" {
  description = "Display name of the Entra ID user/group that administers SQL (e.g. your UPN)."
  type        = string
}

variable "sql_admin_object_id" {
  description = "Object ID of that Entra ID user/group."
  type        = string
}

variable "allowed_client_ips" {
  description = "Public IPs (your home IP) allowed through the SQL firewall."
  type        = list(string)
  default     = []
}
