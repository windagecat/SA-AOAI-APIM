resource "azurerm_portal_dashboard" "my-board" {
  name                = "aoai_api_dashboard_${random_string.random.id}"
  resource_group_name = azurerm_resource_group.test_ai_service.name
  location            = azurerm_resource_group.test_ai_service.location
  dashboard_properties = templatefile("${path.module}/files/dashboard/API_aoai_PF.json",
    {
      apim_name      = azurerm_api_management.test_ai_service.name
      apim_id        = azurerm_api_management.test_ai_service.id
      appinsights_id = azurerm_application_insights.apim.id
    }
  )
}
