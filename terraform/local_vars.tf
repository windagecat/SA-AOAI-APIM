locals {
  subscription_id = "<サブスクリプションID>" #サブスクリプションIDを記入
  openai = {
    account = ["primary", "secondary"] # 編集しないこと
    model = {
      # 下記URLを参照して以下aoaiパラメータを入力すること
      # https://learn.microsoft.com/ja-jp/azure/ai-services/openai/concepts/models?tabs=global-standard%2Cstandard-chat-completions#gpt-4
      location   = "eastus2"     # AOAIインスタンスをデプロイする場所
      model      = "gpt-4o-mini" # aoaiモデル
      version    = "2024-07-18"  # aoaiモデルバージョン
      deploytype = "Standard"    # デプロイの種類。可能な値は、Standard, DataZoneStandard, DataZoneProvisionedManaged, GlobalBatch, GlobalProvisionedManaged, GlobalStandard, ProvisionedManaged 。テスト用にはStandardかGlobalStandardが無難。
      capacity   = 48            # 例) 48=48000トークン。AOAIのcapacityについて、https://learn.microsoft.com/ja-jp/azure/ai-services/openai/quotas-limits#regional-quota-limits　参照
    }
  }
  # 下記NSGルールのパラメータは編集しないこと
  apim_security_rules = [
    {
      name                       = "Client_communication_to_API_Management"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = ""
      destination_port_ranges    = ["80"]
      source_address_prefix      = "Internet"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "Secure_Client_communication_to_API_Management"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = ""
      destination_port_ranges    = ["443"]
      source_address_prefix      = "Internet"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "Management_endpoint_for_Azure_portal_and_Powershell"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = ""
      destination_port_ranges    = ["3443"]
      source_address_prefix      = "ApiManagement"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "Dependency_on_Redis_Cache"
      priority                   = 130
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = ""
      destination_port_ranges    = ["6381-6383"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "Dependency_to_sync_Rate_Limit_Inbound"
      priority                   = 135
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = ""
      destination_port_ranges    = ["4290"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "Azure_Infrastructure_Load_Balancer"
      priority                   = 180
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      destination_port_ranges    = []
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "Dependency_on_Azure_Storage"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = ""
      destination_port_ranges    = ["443"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "Storage"
    },
    {
      name                       = "Dependency_on_Azure_SQL"
      priority                   = 140
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = ""
      destination_port_ranges    = ["1433"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "Sql"
    },
    {
      name                       = "Dependency_for_Log_to_event_Hub_policy"
      priority                   = 150
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = ""
      destination_port_ranges    = ["5671"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "EventHub"
    },
    {
      name                       = "Dependency_on_Redis_Cache_outbound"
      priority                   = 160
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = ""
      destination_port_ranges    = ["6381-6383"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "Depenedency_To_sync_RateLimit_Outbound"
      priority                   = 165
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = ""
      destination_port_ranges    = ["4290"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "Dependency_on_Azure_File_Share_for_GIT"
      priority                   = 170
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = ""
      destination_port_ranges    = ["445"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "Storage"
    },
    {
      name                       = "Publish_DiagnosticLogs_And_Metrics"
      priority                   = 185
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = ""
      destination_port_ranges    = ["443", "12000", "1886"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "AzureMonitor"
    },
    {
      name                       = "Connect_To_SMTP_Relay_For_SendingEmails"
      priority                   = 190
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = ""
      destination_port_ranges    = ["25", "587", "25028"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "Internet"
    },
    {
      name                       = "Authenticate_To_Azure_Active_Directory"
      priority                   = 200
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = ""
      destination_port_ranges    = ["80", "443"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "AzureActiveDirectory"
    },
    {
      name                       = "Publish_Monitoring_Logs"
      priority                   = 300
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = ""
      destination_port_ranges    = ["443"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "AzureCloud"
    },
    {
      name                       = "Access_KeyVault"
      priority                   = 350
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = ""
      destination_port_ranges    = ["443"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "AzureKeyVault"
    },
    {
      name                       = "Deny_All_Internet_Outbound"
      priority                   = 999
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      destination_port_ranges    = []
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "Internet"
    },
  ]
}
