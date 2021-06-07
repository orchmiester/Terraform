
variable "cloudmanager_refresh_token" {
    default = "68pPoDu1SVPWVy2ivXdBXNBO77uFcV8wjeDpq8gHpi7Oc" #Your refresh token here
}
# Azure Subscription Id
variable "azure-subscription-id" {
  type        = string
  description = "Azure Subscription Id"
}
# Azure Client Id/appId
variable "azure-client-id" {
  type        = string
  description = "Azure Client Id/appId"
}
# Azure Client Secret
variable "azure-client-secret" {
  type        = string
  description = "Azure Client secret"
}
# Azure Tenant Id
variable "azure-tenant-id" {
  type        = string
  description = "Azure Tenant Id"
}