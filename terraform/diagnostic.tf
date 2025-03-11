resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${random_string.random.id}"
  location            = azurerm_resource_group.test_ai_service.location
  resource_group_name = azurerm_resource_group.test_ai_service.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "apim" {
  name                = "apim-appinsights-${random_string.random.id}"
  location            = azurerm_resource_group.test_ai_service.location
  resource_group_name = azurerm_resource_group.test_ai_service.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.law.id
}

resource "azurerm_api_management_logger" "application_insight" {
  name                = "application_insight"
  api_management_name = azurerm_api_management.test_ai_service.name
  resource_group_name = azurerm_resource_group.test_ai_service.name
  resource_id         = azurerm_application_insights.apim.id
  application_insights {
    instrumentation_key = azurerm_application_insights.apim.instrumentation_key
  }
}

resource "azurerm_api_management_api_diagnostic" "openai" {
  identifier               = "applicationinsights"
  api_management_name      = azurerm_api_management.test_ai_service.name
  resource_group_name      = azurerm_resource_group.test_ai_service.name
  api_name                 = azurerm_api_management_api.openai.name
  api_management_logger_id = azurerm_api_management_logger.application_insight.id

  sampling_percentage       = 100.0
  always_log_errors         = true
  log_client_ip             = true
  verbosity                 = "information"
  http_correlation_protocol = "Legacy"

  frontend_request {
    body_bytes     = 0
    headers_to_log = []
  }

  frontend_response {
    body_bytes     = 0
    headers_to_log = []
  }

  backend_request {
    body_bytes     = 0
    headers_to_log = []
  }

  backend_response {
    body_bytes     = 0
    headers_to_log = []
  }
}

resource "azapi_update_resource" "apim_openai_api_diagnostic" {
  type        = "Microsoft.ApiManagement/service/apis/diagnostics@2024-06-01-preview"
  resource_id = azurerm_api_management_api_diagnostic.openai.id
  body = {
    properties = {
      metrics = true
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "apim_test_ai_service" {
  name                           = "send-to-law"
  target_resource_id             = azurerm_api_management.test_ai_service.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.law.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "openai" {
  for_each                   = { for i in local.openai.account : i => local.openai.model }
  name                       = "send-to-law"
  target_resource_id         = azurerm_cognitive_account.openai[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category_group = "allLogs"
  }

  metric {
    category = "AllMetrics"
  }
}
