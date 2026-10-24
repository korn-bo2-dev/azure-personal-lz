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

variable "federated_credentials" {
  description = <<-EOT
    Federated identity credentials for the CI/CD identity. Works for both
    GitHub Actions and Azure DevOps service connections, e.g.
      github = {
        issuer  = "https://token.actions.githubusercontent.com"
        subject = "repo:<owner>/azure-personal-lz:environment:prod"
      }
  EOT
  type = map(object({
    issuer  = string
    subject = string
  }))
  default = {}
}

variable "tags" {
  type = map(string)
  default = {
    environment = "personal"
    managed-by  = "terraform"
    workload    = "platform"
  }
}
