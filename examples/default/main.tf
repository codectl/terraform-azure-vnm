module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "default"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "westeurope"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

data "azurerm_subscription" "current" {}

module "virtual_network_manager" {
  source  = "codectl/vnm/azure"
  version = "~> 1.0"

  network_manager = {
    name                = module.naming.virtual_network_manager.name_unique
    resource_group_name = module.rg.groups.demo.name
    location            = module.rg.groups.demo.location
    scope_accesses      = ["Connectivity"]
    subscription_ids    = [data.azurerm_subscription.current.id]
  }
}
