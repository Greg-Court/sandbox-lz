resource "azurerm_firewall_policy" "primary" {
  name                = "afwp-hub-${var.loc_short}-01"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.loc
  dns {
    proxy_enabled = true
    servers       = ["168.63.129.16"]
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "default" {
  name               = "Azure-Default-RCG"
  firewall_policy_id = azurerm_firewall_policy.primary.id
  priority           = 2000

  network_rule_collection {
    name     = "Allow-Internal-NRC"
    priority = 1000
    action   = "Allow"

    rule {
      name                  = "East-West"
      description           = "Allow Any East-West traffic"
      source_ip_groups      = [azurerm_ip_group.shared.id]
      destination_ip_groups = [azurerm_ip_group.shared.id]
      destination_ports     = ["*"]
      protocols             = ["Any"]
    }

  }


  network_rule_collection {
    name     = "Allow-External-NRC"
    priority = 2000
    action   = "Allow"

    rule {
      name                  = "Internet"
      description           = "Allow Any Internet"
      source_ip_groups      = [azurerm_ip_group.shared.id]
      destination_addresses = ["*"]
      destination_ports     = ["*"]
      protocols             = ["Any"]
    }

  }

}

resource "azurerm_firewall_policy_rule_collection_group" "platform" {
  name               = "Azure-Platform-RCG"
  firewall_policy_id = azurerm_firewall_policy.primary.id
  priority           = 1000

  network_rule_collection {
    name     = "Allow-Azure-Platform-Services-NRC"
    priority = 1000
    action   = "Allow"

    rule {
      name                  = "KMS"
      description           = "Allow KMS (Windows Activation)"
      source_ip_groups      = [azurerm_ip_group.shared.id]
      destination_addresses = ["23.102.135.246", "20.118.99.224", "40.83.235.53"]
      destination_ports     = ["1688"]
      protocols             = ["TCP"]
    }

    rule {
      name                  = "Azure-WireServer"
      description           = "Azure platform resources"
      source_ip_groups      = [azurerm_ip_group.shared.id]
      destination_addresses = ["168.63.129.16"]
      destination_ports     = ["80", "32526"]
      protocols             = ["TCP"]
    }

    rule {
      name              = "Windows-Time"
      description       = "Windows Time"
      source_ip_groups  = [azurerm_ip_group.shared.id]
      destination_fqdns = ["time.windows.com"]
      destination_ports = ["123"]
      protocols         = ["UDP"]
    }

    rule {
      name                  = "DNS-Inbound"
      description           = "Allow DNS Inbound"
      source_ip_groups      = [azurerm_ip_group.shared.id]
      destination_addresses = [azurerm_firewall.primary.ip_configuration.0.private_ip_address]
      destination_ports     = ["53"]
      protocols             = ["Any"]
    }

    rule {
      name                  = "DNS-Outbound"
      description           = "Allow DNS Outbound"
      source_addresses      = [azurerm_firewall.primary.ip_configuration.0.private_ip_address]
      destination_addresses = ["168.63.129.16"]
      destination_ports     = ["53"]
      protocols             = ["Any"]
    }

    rule {
      name                  = "Microsoft-Defender-For-Endpoint"
      description           = "Allow Microsoft Defender for Endpoint"
      source_ip_groups      = [azurerm_ip_group.shared.id]
      destination_addresses = ["MicrosoftDefenderForEndpoint"]
      destination_ports     = ["80", "443"]
      protocols             = ["Any"]
    }

    rule {
      name                  = "Microsoft-Entra-ID"
      description           = "Allow Microsoft Entra ID"
      source_ip_groups      = [azurerm_ip_group.shared.id]
      destination_addresses = ["AzureActiveDirectory"]
      destination_ports     = ["443"]
      protocols             = ["Any"]
    }

    rule {
      name                  = "Azure-Storage"
      description           = "Allow Azure Storage"
      source_ip_groups      = [azurerm_ip_group.shared.id]
      destination_addresses = ["Storage"]
      destination_ports     = ["443"]
      protocols             = ["Any"]
    }

    rule {
      name                  = "Azure-Events-Hub"
      description           = "Allow Azure Events Hub"
      source_ip_groups      = [azurerm_ip_group.shared.id]
      destination_addresses = ["EventHub"]
      destination_ports     = ["443"]
      protocols             = ["Any"]
    }

    rule {
      name                  = "Azure-Guest-And-Hybrid-Management"
      description           = "Allow Guest and Hybrid Management"
      source_ip_groups      = [azurerm_ip_group.shared.id]
      destination_addresses = ["GuestAndHybridManagement"]
      destination_ports     = ["443"]
      protocols             = ["Any"]
    }

    rule {
      name                  = "Azure-Key-Vault"
      description           = "Allow Azure Key Vault"
      source_ip_groups      = [azurerm_ip_group.shared.id]
      destination_addresses = ["AzureKeyVault"]
      destination_ports     = ["443"]
      protocols             = ["Any"]
    }

    rule {
      name                  = "Azure-Site-Recovery"
      description           = "Allow Azure Site Recovery"
      source_ip_groups      = [azurerm_ip_group.shared.id]
      destination_addresses = ["AzureSiteRecovery"]
      destination_ports     = ["443"]
      protocols             = ["Any"]
    }

  }

  application_rule_collection {
    name     = "Allow-Azure-Platform-Services-ARC"
    priority = 2000
    action   = "Allow"

    rule {
      name             = "Azure-Backup"
      source_ip_groups = [azurerm_ip_group.shared.id]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdn_tags = ["AzureBackup"]
    }

    rule {
      name             = "Azure-Virtual-Desktop"
      source_ip_groups = [azurerm_ip_group.shared.id]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdn_tags = ["WindowsVirtualDesktop"]
    }

    rule {
      name             = "Azure-Monitor-Agent"
      source_ip_groups = [azurerm_ip_group.shared.id]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = [
        "global.handler.control.monitor.azure.com",
        "${var.loc}.handler.control.monitor.azure.com",
        "*.ods.opinsights.azure.com",
        "management.azure.com",
        "${var.loc}.monitoring.azure.com"
      ]
    }

    rule {
      name             = "Windows-Update"
      source_ip_groups = [azurerm_ip_group.shared.id]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdn_tags = ["WindowsUpdate"]
    }

    rule {
      name             = "Windows-Diagnostics"
      source_ip_groups = [azurerm_ip_group.shared.id]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdn_tags = ["WindowsDiagnostics"]
    }

    rule {
      name             = "MAPS"
      source_ip_groups = [azurerm_ip_group.shared.id]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdn_tags = ["MicrosoftActiveProtectionService"]
    }

    rule {
      name             = "Certificate-Authorities"
      source_ip_groups = [azurerm_ip_group.shared.id]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = [
        "cacerts.digicert.com",
        "cacerts.digicert.cn",
        "cacerts.geotrust.com",
        "www.microsoft.com",
        "crl.microsoft.com",
        "crl3.digicert.com",
        "crl4.digicert.com",
        "crl.digicert.cn",
        "cdp.geotrust.com",
        "mscrl.microsoft.com",
        "ocsp.msocsp.com",
        "ocsp.digicert.com",
        "ocsp.digicert.cn",
        "oneocsp.microsoft.com",
        "status.geotrust.com"
      ]
      # terminate_tls = true
    }
  }
}