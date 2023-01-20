resource "azurerm_resource_group" "RG" {
  name     = "RG-UNIVERSIDADE-TERRAFORM"
  location = "Brazil South"
}

resource "azurerm_virtual_network" "VNET" {
  name                = "vnet-network"
  address_space       = ["10.224.0.0/16"]
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
}

resource "azurerm_subnet" "SUBNET" {
  name                 = "default_01"
  resource_group_name  = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes     = ["10.224.2.0/24"]
}

resource "azurerm_network_interface" "NIC" {
  name                = "nic-vm-01"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  ip_configuration {
    name                          = "private-ip"
    subnet_id                     = azurerm_subnet.SUBNET.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "random_password" "senha" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_linux_virtual_machine" "VM" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location
  size                = "Standard_B2s"
  network_interface_ids = [
    azurerm_network_interface.NIC.id,
  ]

     os_profile {
     computer_name = "VM-01"
     admin_username = "alx3000"
     admin_password = random_password.senha.result
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