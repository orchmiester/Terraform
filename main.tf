terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.45.1"
    }
    netapp-cloudmanager = {
      source = "NetApp/netapp-cloudmanager"
      version = "20.12.3"
    }
  }
}

provider "azurerm" { 
  subscription_id = var.azure-subscription-id
  client_id       = var.azure-client-id
  client_secret   = var.azure-client-secret 
  tenant_id       = var.azure-tenant-id
  features {}
}

provider "netapp-cloudmanager" {
  refresh_token = var.cloudmanager_refresh_token
}

# Azure Environment

resource "azurerm_resource_group" "terraform-connector-rg" {
  name     = "tfConnectorRG"
  location = "eastus2"
}

resource "azurerm_virtual_network" "TFvnet" {
  name                = "TFvirtualNetwork"
  location            = azurerm_resource_group.terraform-connector-rg.location
  resource_group_name = azurerm_resource_group.terraform-connector-rg.name
  address_space       = ["10.0.10.0/24"]
}

resource "azurerm_subnet" "subnet1" {
  name = "TFsubnet1"
  resource_group_name  = azurerm_resource_group.terraform-connector-rg.name
  virtual_network_name = azurerm_virtual_network.TFvnet.name
  address_prefixes = ["10.0.10.0/25"]
}

resource "azurerm_subnet" "subnet2" {
  name = "TFsubnet2"
  resource_group_name  = azurerm_resource_group.terraform-connector-rg.name
  virtual_network_name = azurerm_virtual_network.TFvnet.name
  address_prefixes = ["10.0.10.128/25"]
}

resource "azurerm_network_security_group" "tf-connector-sg" {
  name                = "tfConnectorSG"
  location            = azurerm_resource_group.terraform-connector-rg.location
  resource_group_name = azurerm_resource_group.terraform-connector-rg.name

  security_rule {
    name                       = "http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "80"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "https"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "443"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ssh"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "22"
    source_port_range          = "*"
    source_address_prefix      = "1.1.1.1/32"
    destination_address_prefix = "*"
  }
}

# Netapp Connector Resources

resource "netapp-cloudmanager_connector_azure" "terraform-connector" {
  provider = netapp-cloudmanager
  name = "tfConnector"
  location = azurerm_resource_group.terraform-connector-rg.location
  subscription_id = var.azure-subscription-id
  company = "NetApp"
  resource_group = azurerm_resource_group.terraform-connector-rg.name
  subnet_id = azurerm_subnet.subnet1.name
  vnet_id = azurerm_virtual_network.TFvnet.name
  network_security_group_name = azurerm_network_security_group.tf-connector-sg.name
  associate_public_ip_address = true
  account_id = "account-48ZMsSAv"
  admin_password = "P@ssword123"
  admin_username = "myuser"
}

data "azurerm_virtual_machine" "tf-connector-vm" {
  depends_on = [netapp-cloudmanager_connector_azure.terraform-connector]
  name                = netapp-cloudmanager_connector_azure.terraform-connector.name
  resource_group_name = azurerm_resource_group.terraform-connector-rg.name
}

resource "azurerm_role_definition" "tf-connector-role" {
  name        = "tf-connector-role"
  scope       = "/subscriptions/${var.azure-subscription-id}"
  description = "This is a custom role created via Terraform"

  permissions {
    actions     = ["Microsoft.Compute/disks/delete",
        "Microsoft.Compute/disks/read",
        "Microsoft.Compute/disks/write",
        "Microsoft.Compute/locations/operations/read",
        "Microsoft.Compute/locations/vmSizes/read",
        "Microsoft.Resources/subscriptions/locations/read",
        "Microsoft.Compute/operations/read",
        "Microsoft.Compute/virtualMachines/instanceView/read",
        "Microsoft.Compute/virtualMachines/powerOff/action",
        "Microsoft.Compute/virtualMachines/read",
        "Microsoft.Compute/virtualMachines/restart/action",
        "Microsoft.Compute/virtualMachines/deallocate/action",
        "Microsoft.Compute/virtualMachines/start/action",
        "Microsoft.Compute/virtualMachines/vmSizes/read",
        "Microsoft.Compute/virtualMachines/write",
        "Microsoft.Compute/images/write",
        "Microsoft.Compute/images/read",
        "Microsoft.Network/locations/operationResults/read",
        "Microsoft.Network/locations/operations/read",
        "Microsoft.Network/networkInterfaces/read",
        "Microsoft.Network/networkInterfaces/write",
        "Microsoft.Network/networkInterfaces/join/action",
        "Microsoft.Network/networkSecurityGroups/read",
        "Microsoft.Network/networkSecurityGroups/write",
        "Microsoft.Network/networkSecurityGroups/join/action",
        "Microsoft.Network/virtualNetworks/read",
        "Microsoft.Network/virtualNetworks/checkIpAddressAvailability/read",
        "Microsoft.Network/virtualNetworks/subnets/read",
        "Microsoft.Network/virtualNetworks/subnets/write",
        "Microsoft.Network/virtualNetworks/subnets/virtualMachines/read",
        "Microsoft.Network/virtualNetworks/virtualMachines/read",
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Resources/deployments/operations/read",
        "Microsoft.Resources/deployments/read",
        "Microsoft.Resources/deployments/write",
        "Microsoft.Resources/resources/read",
        "Microsoft.Resources/subscriptions/operationresults/read",
        "Microsoft.Resources/subscriptions/resourceGroups/delete",
        "Microsoft.Resources/subscriptions/resourceGroups/read",
        "Microsoft.Resources/subscriptions/resourcegroups/resources/read",
        "Microsoft.Resources/subscriptions/resourceGroups/write",
        "Microsoft.Storage/checknameavailability/read",
        "Microsoft.Storage/operations/read",
        "Microsoft.Storage/storageAccounts/listkeys/action",
        "Microsoft.Storage/storageAccounts/read",
        "Microsoft.Storage/storageAccounts/delete",
        "Microsoft.Storage/storageAccounts/regeneratekey/action",
        "Microsoft.Storage/storageAccounts/write",
        "Microsoft.Storage/usages/read",
        "Microsoft.Compute/snapshots/write",
        "Microsoft.Compute/snapshots/read",
        "Microsoft.Compute/availabilitySets/write",
        "Microsoft.Compute/availabilitySets/read",
        "Microsoft.Compute/disks/beginGetAccess/action",
        "Microsoft.MarketplaceOrdering/offertypes/publishers/offers/plans/agreements/read",
        "Microsoft.MarketplaceOrdering/offertypes/publishers/offers/plans/agreements/write",
        "Microsoft.Network/loadBalancers/read",
        "Microsoft.Network/loadBalancers/write",
        "Microsoft.Network/loadBalancers/delete",
        "Microsoft.Network/loadBalancers/backendAddressPools/read",
        "Microsoft.Network/loadBalancers/backendAddressPools/join/action",
        "Microsoft.Network/loadBalancers/frontendIPConfigurations/read",
        "Microsoft.Network/loadBalancers/loadBalancingRules/read",
        "Microsoft.Network/loadBalancers/probes/read",
        "Microsoft.Network/loadBalancers/probes/join/action",
        "Microsoft.Authorization/locks/*",
        "Microsoft.Network/routeTables/join/action",
        "Microsoft.NetApp/netAppAccounts/capacityPools/volumes/write",
        "Microsoft.NetApp/netAppAccounts/capacityPools/volumes/read",
        "Microsoft.NetApp/netAppAccounts/capacityPools/volumes/delete",
        "Microsoft.NetApp/netAppAccounts/write",
        "Microsoft.NetApp/netAppAccounts/read",
        "Microsoft.NetApp/netAppAccounts/capacityPools/write",
        "Microsoft.NetApp/netAppAccounts/capacityPools/read",
        "Microsoft.NetApp/netAppAccounts/capacityPools/volumes/delete",
        "Microsoft.Network/privateEndpoints/write",
        "Microsoft.Storage/storageAccounts/PrivateEndpointConnectionsApproval/action",
        "Microsoft.Storage/storageAccounts/privateEndpointConnections/read",
        "Microsoft.Network/privateEndpoints/read",
        "Microsoft.Network/privateDnsZones/write",
        "Microsoft.Network/privateDnsZones/virtualNetworkLinks/write",
        "Microsoft.Network/virtualNetworks/join/action",
        "Microsoft.Network/privateDnsZones/A/write",
        "Microsoft.Network/privateDnsZones/read",
        "Microsoft.Network/privateDnsZones/virtualNetworkLinks/read",
        "Microsoft.Resources/deployments/operationStatuses/read",
        "Microsoft.Insights/Metrics/Read",
        "Microsoft.Compute/virtualMachines/extensions/write",
        "Microsoft.Compute/virtualMachines/extensions/read",
        "Microsoft.Compute/virtualMachines/extensions/delete",
        "Microsoft.Compute/virtualMachines/delete",
        "Microsoft.Network/networkInterfaces/delete",
        "Microsoft.Network/networkSecurityGroups/delete",
        "Microsoft.Resources/deployments/delete",
        "Microsoft.Compute/diskEncryptionSets/read"]
    not_actions = []
  }

  assignable_scopes = [
    "/subscriptions/${var.azure-subscription-id}",
  ]
}

resource "azurerm_role_assignment" "occm-role-assignment" {
  depends_on         = [azurerm_role_definition.tf-connector-role]
  scope              = "/subscriptions/${var.azure-subscription-id}"
  role_definition_id = azurerm_role_definition.tf-connector-role.role_definition_resource_id 
  principal_id       = data.azurerm_virtual_machine.tf-connector-vm.identity.0.principal_id
}

# Netapp CVO resources

resource "netapp-cloudmanager_cvo_azure" "cl-azure" {
  depends_on            = [azurerm_role_assignment.occm-role-assignment]
  provider              = netapp-cloudmanager
  name                  = "terraformCVO"
  location              = azurerm_resource_group.terraform-connector-rg.location
  subscription_id       = var.azure-subscription-id
  subnet_id             = azurerm_subnet.subnet1.name
  vnet_id               = azurerm_virtual_network.TFvnet.name
  vnet_resource_group   = azurerm_resource_group.terraform-connector-rg.name
  data_encryption_type  = "AZURE"
  storage_type          = "Standard_LRS"
  svm_password          = "P@ssword123"
  client_id             = netapp-cloudmanager_connector_azure.terraform-connector.client_id
  workspace_id          = "workspace-Ag5bi9qM"
  capacity_tier         = "Blob"
  is_ha                 = true
  license_type          = "azure-ha-cot-standard-paygo"
  disk_size             = 2
  disk_size_unit        = "TB"
  use_latest_version    = true
  instance_type         = "Standard_DS4_v2"
}
