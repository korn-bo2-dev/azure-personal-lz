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
