

resource "azurerm_resource_group" "resource_group" {
  name     = "dev-rg"
  location = "West Europe"
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = "dev-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = local.location
  resource_group_name = local.resource_group_name

  depends_on = [ azurerm_resource_group.resource_group ]
}

resource "azurerm_subnet" "snet" {
  name                 = "internal"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.2.0/24"]

  depends_on = [ azurerm_resource_group.resource_group,azurerm_virtual_network.virtual_network ]
}

resource "azurerm_network_interface" "network_interface" {
  name                = "dev-nic"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  depends_on = [ azurerm_resource_group.resource_group,azurerm_subnet.snet]
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "dev-vm01"
  resource_group_name = local.resource_group_name
  location            = local.location
  size                = "Standard_F2"
  admin_username      = data.azurerm_key_vault_secret.username.value
  admin_password      = data.azurerm_key_vault_secret.password.value
  network_interface_ids = [
    azurerm_network_interface.network_interface.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  depends_on = [ azurerm_resource_group.resource_group,azurerm_network_interface.network_interface, azurerm_subnet.snet,azurerm_windows_virtual_machine.vm,data.azurerm_key_vault.kv,data.azurerm_key_vault_secret.username,data.azurerm_key_vault_secret.password]
}


resource "azurerm_public_ip" "pip" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = "Static"
}

