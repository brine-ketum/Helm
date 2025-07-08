# modules/registry/main.tf

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled
  
  # Geo-replication (only for Premium SKU)
  dynamic "georeplications" {
    for_each = var.sku == "Premium" ? var.georeplications : []
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
      tags                    = georeplications.value.tags
    }
  }
  
  # Retention policy (only for Premium SKU)
  dynamic "retention_policy" {
    for_each = var.sku == "Premium" && var.retention_policy != null ? [var.retention_policy] : []
    content {
      days    = retention_policy.value.days
      enabled = retention_policy.value.enabled
    }
  }
  
  # Trust policy
  dynamic "trust_policy" {
    for_each = var.sku == "Premium" && var.trust_policy_enabled ? [1] : []
    content {
      enabled = true
    }
  }
  
  # Encryption (only for Premium SKU)
  dynamic "encryption" {
    for_each = var.sku == "Premium" && var.encryption != null ? [var.encryption] : []
    content {
      enabled            = true
      key_vault_key_id   = encryption.value.key_vault_key_id
      identity_client_id = encryption.value.identity_client_id
    }
  }
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
}

# Webhook (optional)
resource "azurerm_container_registry_webhook" "main" {
  for_each = var.webhooks
  
  name                = each.key
  resource_group_name = var.resource_group_name
  registry_name       = azurerm_container_registry.main.name
  location            = var.location
  
  service_uri    = each.value.service_uri
  actions        = each.value.actions
  status         = lookup(each.value, "status", "enabled")
  scope          = lookup(each.value, "scope", "")
  custom_headers = lookup(each.value, "custom_headers", {})
  
  tags = merge(var.tags, lookup(each.value, "tags", {}))
}

# Tasks (Build tasks) - only for Standard and Premium SKUs
resource "azurerm_container_registry_task" "main" {
  for_each = var.sku != "Basic" ? var.tasks : {}
  
  name                  = each.key
  container_registry_id = azurerm_container_registry.main.id
  
  platform {
    os           = lookup(each.value.platform, "os", "Linux")
    architecture = lookup(each.value.platform, "architecture", "amd64")
    variant      = lookup(each.value.platform, "variant", null)
  }
  
  docker_step {
    dockerfile_path      = each.value.dockerfile_path
    context_path         = each.value.context_path
    context_access_token = lookup(each.value, "context_access_token", null)
    image_names          = each.value.image_names
    arguments            = lookup(each.value, "build_arguments", {})
    secret_arguments     = lookup(each.value, "secret_arguments", {})
    push_enabled         = lookup(each.value, "push_enabled", true)
    cache_enabled        = lookup(each.value, "cache_enabled", true)
  }
  
  dynamic "source_trigger" {
    for_each = lookup(each.value, "source_triggers", [])
    content {
      name           = source_trigger.value.name
      events         = source_trigger.value.events
      source_type    = source_trigger.value.source_type
      repository_url = source_trigger.value.repository_url
      branch         = lookup(source_trigger.value, "branch", "main")
      
      authentication {
        token      = source_trigger.value.authentication.token
        token_type = source_trigger.value.authentication.token_type
      }
    }
  }
  
  tags = merge(var.tags, lookup(each.value, "tags", {}))
}

# Scope Maps (for token-based authentication) - only for Premium SKU
resource "azurerm_container_registry_scope_map" "main" {
  for_each = var.sku == "Premium" ? var.scope_maps : {}
  
  name                    = each.key
  container_registry_name = azurerm_container_registry.main.name
  resource_group_name     = var.resource_group_name
  actions                 = each.value.actions
}

# Tokens - only for Premium SKU
resource "azurerm_container_registry_token" "main" {
  for_each = var.sku == "Premium" ? var.tokens : {}
  
  name                    = each.key
  container_registry_name = azurerm_container_registry.main.name
  resource_group_name     = var.resource_group_name
  scope_map_id           = azurerm_container_registry_scope_map.main[each.value.scope_map].id
  enabled                = lookup(each.value, "enabled", true)
}