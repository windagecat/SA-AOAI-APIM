resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${random_string.random.id}"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.test_ai_service.location
  resource_group_name = azurerm_resource_group.test_ai_service.name
}

resource "azurerm_subnet" "apim" {
  name                 = "apim"
  resource_group_name  = azurerm_resource_group.test_ai_service.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.1.5.240/29"]
  #service_endpoints    = ["Microsoft.CognitiveServices"]
  lifecycle {
    ignore_changes = [
      service_endpoints,
    ]
  }
}

resource "azapi_update_resource" "apim_subnet" {
  type        = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  resource_id = azurerm_subnet.apim.id
  body = {
    properties = {
      serviceEndpoints = [
        {
          locations = [
            "*"
          ]
          service = "Microsoft.CognitiveServices"
        }
      ]
    }
  }
}

resource "azurerm_network_security_group" "apim" {
  name                = "apim-nsg-${random_string.random.id}"
  location            = azurerm_resource_group.test_ai_service.location
  resource_group_name = azurerm_resource_group.test_ai_service.name

  dynamic "security_rule" {
    for_each = local.apim_security_rules

    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      destination_port_ranges    = security_rule.value.destination_port_ranges
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "apim" {
  subnet_id                 = azurerm_subnet.apim.id
  network_security_group_id = azurerm_network_security_group.apim.id
}
