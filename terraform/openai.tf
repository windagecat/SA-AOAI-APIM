resource "azurerm_cognitive_account" "openai" {
  for_each              = { for i in local.openai.account : i => local.openai.model }
  name                  = "${each.key}-aoai-${random_string.random.id}"
  location              = each.value.location
  resource_group_name   = azurerm_resource_group.test_ai_service.name
  kind                  = "OpenAI"
  sku_name              = "S0"
  custom_subdomain_name = "${each.key}-aoai-${random_string.random.id}"
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"

    virtual_network_rules {
      subnet_id = azurerm_subnet.apim.id
    }
  }
}

resource "azurerm_cognitive_deployment" "test_deployment" {
  for_each             = { for i in local.openai.account : i => local.openai.model }
  name                 = "${each.value.model}_${each.value.version}"
  cognitive_account_id = azurerm_cognitive_account.openai[each.key].id
  model {
    format  = "OpenAI"
    name    = each.value.model
    version = each.value.version
  }
  rai_policy_name = azapi_resource.contentpolicy[each.key].name
  sku {
    name     = each.value.deploytype
    capacity = each.value.capacity
  }
  version_upgrade_option = "NoAutoUpgrade"
}

resource "azapi_resource" "contentpolicy" {
  for_each  = { for i in local.openai.account : i => local.openai.model }
  type      = "Microsoft.CognitiveServices/accounts/raiPolicies@2024-10-01"
  name      = "testcontentpolicy"
  parent_id = azurerm_cognitive_account.openai[each.key].id
  body = {
    properties = {
      basePolicyName = "Microsoft.DefaultV2"
      contentFilters = [
        {
          severityThreshold = "High"
          blocking          = true
          enabled           = true
          name              = "Violence"
          source            = "Prompt"
        },
        {
          severityThreshold = "High"
          blocking          = true
          enabled           = true
          name              = "Hate"
          source            = "Prompt"
        },
        {
          severityThreshold = "High"
          blocking          = true
          enabled           = true
          name              = "Sexual"
          source            = "Prompt"
        },
        {
          severityThreshold = "High"
          blocking          = true
          enabled           = true
          name              = "Selfharm"
          source            = "Prompt"
        },
        {
          blocking = true
          enabled  = true
          name     = "Jailbreak"
          source   = "Prompt"
        },
        {
          blocking = false
          enabled  = false
          name     = "Indirect Attack"
          source   = "Prompt"
        },
        {
          blocking = true
          enabled  = true
          name     = "Profanity"
          source   = "Prompt"
        },
        {
          severityThreshold = "High"
          blocking          = true
          enabled           = true
          name              = "Violence"
          source            = "Completion"
        },
        {
          severityThreshold = "High"
          blocking          = true
          enabled           = true
          name              = "Hate"
          source            = "Completion"
        },
        {
          severityThreshold = "High"
          blocking          = true
          enabled           = true
          name              = "Sexual"
          source            = "Completion"
        },
        {
          severityThreshold = "High"
          blocking          = true
          enabled           = true
          name              = "Selfharm"
          source            = "Completion"
        },
        {
          blocking = true
          enabled  = true
          name     = "Jailbreak"
          source   = "Completion"
        },
        {
          blocking = false
          enabled  = false
          name     = "Indirect Attack"
          source   = "Completion"
        },
        {
          blocking = true
          enabled  = true
          name     = "Profanity"
          source   = "Completion"
        },
      ]
      mode = "Default"
    }
  }
}
