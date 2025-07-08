# modules/service-principal/main.tf

# Azure AD Application
resource "azuread_application" "main" {
  display_name = var.display_name
  description  = var.description
  
  api {
    mapped_claims_enabled          = false
    requested_access_token_version = 2
  }
  
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
    
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }
}

# Service Principal
resource "azuread_service_principal" "main" {
  client_id                    = azuread_application.main.client_id
  app_role_assignment_required = false
  description                  = var.description
  
  feature_tags {
    enterprise = true
    gallery    = false
  }
}

# Service Principal Password
resource "azuread_service_principal_password" "main" {
  service_principal_id = azuread_service_principal.main.id
  display_name         = var.password_display_name
  end_date             = var.password_end_date
}

# Grant permissions
resource "azuread_app_role_assignment" "main" {
  for_each = var.app_role_assignments
  
  app_role_id         = each.value.app_role_id
  principal_object_id = azuread_service_principal.main.object_id
  resource_object_id  = each.value.resource_object_id
}
