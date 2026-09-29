module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
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

module "networks" {
  source   = "codectl/vnet/azure"
  version  = "~> 1.0"
  for_each = local.vnet

  vnet = each.value
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

    network_groups = {
      all_networks = {
        name        = "all-networks-with-spokes"
        description = "Network group containing hub and all spoke networks"
      }
    }

    static_members = {
      hub_member = {
        network_group_key         = "all_networks"
        name                      = "hub-member"
        target_virtual_network_id = module.networks["hub"].vnet.id
      }
      spoke1_member = {
        network_group_key         = "all_networks"
        name                      = "spoke1-member"
        target_virtual_network_id = module.networks["spoke1"].vnet.id
      }
      spoke2_member = {
        network_group_key         = "all_networks"
        name                      = "spoke2-member"
        target_virtual_network_id = module.networks["spoke2"].vnet.id
      }
    }

    connectivity_configurations = {
      hub_spoke = {
        name                  = "hub-spoke-connectivity"
        description           = "Hub-and-spoke connectivity configuration"
        connectivity_topology = "HubAndSpoke"

        applies_to_groups = [{
          network_group_key   = "all_networks"
          group_connectivity  = "None"
          global_mesh_enabled = false
          use_hub_gateway     = false
        }]

        hub = {
          resource_id   = module.networks["hub"].vnet.id
          resource_type = "Microsoft.Network/virtualNetworks"
        }
      }
    }
  }

}


