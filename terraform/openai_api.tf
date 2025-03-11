resource "azurerm_api_management_api" "openai" {
  name                  = "openai"
  resource_group_name   = azurerm_resource_group.test_ai_service.name
  api_management_name   = azurerm_api_management.test_ai_service.name
  revision              = "1"
  display_name          = "openai api"
  path                  = "openai"
  protocols             = ["https"]
  subscription_required = true
  subscription_key_parameter_names {
    header = "api-key"
    query  = "subscription-key"
  }
  import {
    content_format = "openapi"
    content_value = templatefile("${path.module}/files/api/openai_openapi.yaml",
      {
        apim_gateway_url   = azurerm_api_management.test_ai_service.gateway_url
        aoai_model         = local.openai.model.model
        aoai_model_version = local.openai.model.version
      }
    )
  }
}

resource "azurerm_api_management_backend" "aoai" {
  for_each            = { for i in local.openai.account : i => local.openai.model }
  name                = "${each.key}-aoai"
  resource_group_name = azurerm_resource_group.test_ai_service.name
  api_management_name = azurerm_api_management.test_ai_service.name
  protocol            = "http"
  url                 = "${azurerm_cognitive_account.openai[each.key].endpoint}openai"
}

resource "azurerm_api_management_api_policy" "openai" {
  api_name            = azurerm_api_management_api.openai.name
  api_management_name = azurerm_api_management.test_ai_service.name
  resource_group_name = azurerm_resource_group.test_ai_service.name
  xml_content = templatefile("${path.module}/files/policy/aoai_api.xml",
    {
      fragment_backend = azurerm_api_management_policy_fragment.backend_aoai.name
    }
  )
}

resource "azurerm_api_management_policy_fragment" "backend_aoai" {
  api_management_id = azurerm_api_management.test_ai_service.id
  name              = "backend-aoai"
  format            = "rawxml"
  value = templatefile("${path.module}/files/fragment/backend_aoai.xml",
    {
      primary-aoai   = azurerm_api_management_backend.aoai["primary"].name
      secondary-aoai = azurerm_api_management_backend.aoai["secondary"].name
    }
  )
}

resource "azurerm_api_management_policy_fragment" "backend_aoai_retry" {
  api_management_id = azurerm_api_management.test_ai_service.id
  name              = "backend-aoai-retry"
  format            = "rawxml"
  value = templatefile("${path.module}/files/fragment/backend_aoai_retry.xml",
    {
      secondary-aoai = azurerm_api_management_backend.aoai["secondary"].name
    }
  )
}

resource "azurerm_api_management_api_operation_policy" "openai_operation" {
  api_name            = azurerm_api_management_api.openai.name
  api_management_name = azurerm_api_management.test_ai_service.name
  resource_group_name = azurerm_resource_group.test_ai_service.name
  operation_id        = "ChatCompletions_Create-${local.openai.model.model}_${local.openai.model.version}"

  xml_content = templatefile("${path.module}/files/policy/aoai_operation.xml",
    {
      backend-aoai = azurerm_api_management_policy_fragment.backend_aoai.name
      retry        = azurerm_api_management_policy_fragment.backend_aoai_retry.name
    }
  )
}

resource "azurerm_api_management_product" "sa_openai_api" {
  product_id            = "sa-openai-api"
  api_management_name   = azurerm_api_management.test_ai_service.name
  resource_group_name   = azurerm_resource_group.test_ai_service.name
  display_name          = "SA Openai Api"
  subscription_required = true
  approval_required     = false
  published             = true
}

resource "azurerm_api_management_product_api" "sa_openai_api" {
  api_name            = azurerm_api_management_api.openai.name
  api_management_name = azurerm_api_management.test_ai_service.name
  resource_group_name = azurerm_resource_group.test_ai_service.name
  product_id          = azurerm_api_management_product.sa_openai_api.product_id
}

resource "azurerm_api_management_subscription" "sa_openai_api" {
  api_management_name = azurerm_api_management.test_ai_service.name
  resource_group_name = azurerm_resource_group.test_ai_service.name
  product_id          = azurerm_api_management_product.sa_openai_api.id
  display_name        = "test_sa_openai_api"
  subscription_id     = "testsaopenaiapi"
  allow_tracing       = false
  state               = "active"
}
