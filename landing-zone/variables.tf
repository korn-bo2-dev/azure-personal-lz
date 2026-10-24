variable "location" {
  description = "Primary Azure region."
  type        = string
  default     = "australiaeast"
}

variable "platform_subscription_id" {
  description = "Platform subscription (management, identity and, later, connectivity). Also holds Terraform state."
  type        = string
}

variable "prod_subscription_id" {
  description = "Production workload subscription. Placed in the Corp landing zone."
  type        = string
}

variable "dev_subscription_id" {
  description = "Development workload subscription. Placed in the Corp landing zone."
  type        = string
}

variable "security_contact_email" {
  description = "Email for Defender for Cloud security contact, service health and budget alerts."
  type        = string
}

variable "budget_amounts" {
  description = "Monthly budget per subscription, in the billing currency."
  type = object({
    platform = number
    prod     = number
    dev      = number
  })
  default = {
    platform = 30
    prod     = 30
    dev      = 20
  }
}

variable "log_analytics_daily_quota_gb" {
  description = "Hard cap on Log Analytics ingestion per day. -1 means unlimited."
  type        = number
  default     = 1
}

variable "defender_plans_enabled" {
  description = "Let ALZ policies turn on paid Microsoft Defender for Cloud plans. Off by default to avoid charges."
  type        = bool
  default     = false
}

variable "cicd_identity_name" {
  description = "Name of the CI/CD managed identity created by bootstrap (in rg-tfstate, platform subscription)."
  type        = string
  default     = "id-cicd-landing-zone"
}
