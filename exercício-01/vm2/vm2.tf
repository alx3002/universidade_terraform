provider "azurerm" {
  features {}
}
data "terraform_remote_state" "localstate"{
  backend = "local" 

  config = {
    path = "C:/Users/Alexandre/Documents/github/universidade_terraform/exercício-01/terraform.tfstate"
  }
}
#Criando a NIC
resource "azurerm_network_interface" "NIC" {
  name                = "nic-VM-02"
  location            = data.terraform_remote_state.localstate.outputs.RG_Location
  resource_group_name = data.terraform_remote_state.localstate.outputs.RG_Name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.terraform_remote_state.localstate.outputs.SNET_Id
    private_ip_address_allocation = "Dynamic"
  }
}

#Criando senha RANDOM
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "@#$%!&"
}

#Criando VM
resource "azurerm_linux_virtual_machine" "VM" {
  name                = "VM-02"
  resource_group_name = data.terraform_remote_state.localstate.outputs.RG_Name
  location            = data.terraform_remote_state.localstate.outputs.RG_Location
  admin_username = "adminuser"
  computer_name = "VM-02"
  disable_password_authentication = false
  admin_password = random_password.password.result
  size                = "Standard_B2s"
  network_interface_ids = [
    azurerm_network_interface.NIC.id,
  ]

   boot_diagnostics {
    storage_account_uri = data.terraform_remote_state.localstate.outputs.STGACCOUNT_Uri
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
output vm_admin_passsword {
  description = "Login para usuário admin"
  value     = random_password.password.result
  sensitive = true
}