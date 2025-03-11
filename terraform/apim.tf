resource "random_string" "random" {
  length      = 4
  special     = false
  upper       = false
  min_lower   = 1
  min_numeric = 1
  keepers = {
    rg_name = azurerm_resource_group.test_ai_service.name
  }
}

resource "azurerm_resource_group" "test_ai_service" {
  name     = "testaiapiservice"
  location = "East Asia"
}

resource "azurerm_api_management" "test_ai_service" {
  name                 = "testsaapi${random_string.random.id}"
  location             = azurerm_resource_group.test_ai_service.location
  resource_group_name  = azurerm_resource_group.test_ai_service.name
  publisher_name       = "testcompany"
  publisher_email      = "testuser@test.com"
  sku_name             = "Developer_1"
  virtual_network_type = "External"
  virtual_network_configuration {
    subnet_id = azurerm_subnet.apim.id
  }
  identity {
    type = "SystemAssigned"
  }
  depends_on = [azurerm_network_security_group.apim, ]
}

resource "azurerm_api_management_policy" "test_ai_service" {
  api_management_id = azurerm_api_management.test_ai_service.id
  xml_content = templatefile("${path.module}/files/policy/all_api.xml",
    {
      origin_dev_url = azurerm_api_management.test_ai_service.developer_portal_url
    }
  )
}

resource "azurerm_role_assignment" "openai" {
  scope                = azurerm_resource_group.test_ai_service.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_api_management.test_ai_service.identity[0].principal_id
}
