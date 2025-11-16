resource "azurerm_resource_group" "landing_zone-rg" {
  for_each = var.varlanding
  name     = each.value.rg_name
  location = each.value.location
}

resource "azurerm_virtual_network" "landing_zone-vnet" {
  depends_on          = [azurerm_resource_group.landing_zone-rg]
  for_each            = var.varlanding
  name                = each.value.vnet_name
  location            = each.value.location
  resource_group_name = each.value.rg_name
  address_space       = each.value.address_space
}

resource "azurerm_subnet" "landing-subnet" {
  depends_on           = [azurerm_resource_group.landing_zone-rg, azurerm_virtual_network.landing_zone-vnet]
  for_each             = var.varlanding
  name                 = each.value.subnet_name
  resource_group_name  = each.value.rg_name
  virtual_network_name = each.value.vnet_name
  address_prefixes     = each.value.address_prefixes
}



resource "azurerm_network_interface" "nic" {
  depends_on          = [azurerm_subnet.landing-subnet]
  for_each            = var.varlanding
  name                = each.value.nic_name
  location            = each.value.location
  resource_group_name = each.value.rg_name

  ip_configuration {
    name                          = each.value.ip_config_name
    subnet_id                     = data.azurerm_subnet.subnet_data[each.key].id
    private_ip_address_allocation = "Dynamic"


  }
}


resource "azurerm_linux_virtual_machine" "landing-vm" {
  depends_on                      = [azurerm_network_interface.nic]
  for_each                        = var.varlanding
  name                            = each.value.vm_name
  resource_group_name             = each.value.rg_name
  location                        = each.value.location
  size                            = each.value.vm_size
  admin_username                  = each.value.admin_username
  admin_password                  = each.value.admin_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id,
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}


