terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
}

#Criando um resource group - o "Exemple é o nome do RG dentro do Terraform"
resource "azurerm_resource_group" "RG" {
  name     = "rg-UniversidadeTerraform"
  location = "East US"
}

#Crianddo a VNET - Example é o nome do recurso no terraforms, o Name é o nome do recurso que irá para o azure
resource "azurerm_virtual_network" "VNET" {
  name                = "vnet-universidadeterraform"
  address_space       = ["10.120.0.0/16"]
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
}

#Criando a Subnet - Não esquecer de botar o tipo do recurso, exemplo RG ou VNET
resource "azurerm_subnet" "SNET" {
  name                 = "snet-universidadeterraform"
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes     = ["10.120.1.0/24"]
}

#Criando a NIC
resource "azurerm_network_interface" "NIC" {
  name                = "nic-VM01"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SNET.id
    private_ip_address_allocation = "Dynamic"
  }
}

#Criando senha RANDOM
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "@#$%!&"
}

#Criando STG Account
resource "azurerm_storage_account" "STGACCOUNT" {
  name                     = "stgbootdiagvms"
  resource_group_name      = azurerm_resource_group.RG.name
  location                 = azurerm_resource_group.RG.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

#Criando VM
resource "azurerm_linux_virtual_machine" "VM" {
  name                = "VM-02"
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location
  admin_username = "adminuser"
  computer_name = "VM-02"
  disable_password_authentication = false
  admin_password = random_password.password.result
  size                = "Standard_B2s"
  network_interface_ids = [
    azurerm_network_interface.NIC.id,
  ]

   boot_diagnostics {
    storage_account_uri = azurerm_storage_account.STGACCOUNT.primary_blob_endpoint
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

#Outputs
output "STGACCOUNT_Uri" {
  description = "Id do Storage Account"
  value       = azurerm_storage_account.STGACCOUNT.primary_blob_endpoint
}
output "RG_Name" {
  description = "Nome do Resource Group"
  value       = azurerm_resource_group.RG.name
}
output "RG_Location" {
  description = "Location do Resource Group"
  value       = azurerm_resource_group.RG.location
}
output "SNET_Id" {
    description = "Id da SubNet"
    value = azurerm_subnet.SNET.id
}