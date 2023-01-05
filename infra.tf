terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.48.0"
    }
  }
}

provider "openstack" {
  user_name   = "tenant"
  tenant_name = "Tenant"
  password    = "#Tenant123"
  auth_url    = "http://10.10.0.250:5000/v3/"
  region      = "RegionOne"
}

resource "openstack_networking_network_v2" "private-terraform" {
  name           = "private-terraform-tenant"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "private-terraform-subnet" {
  name       = "private-terraform-subnet-tenant"
  network_id = "${openstack_networking_network_v2.private-terraform.id}"
  cidr       = "172.16.4.0/24"
  ip_version = 4
}

resource "openstack_networking_router_v2" "router" {
  name                = "router-tenant"
  external_network_id = "6166be93-c62d-4c95-a198-5fde14f94527" #existing provider network
}

resource "openstack_networking_router_interface_v2" "private-to-router" {
  router_id = "${openstack_networking_router_v2.router.id}"
  subnet_id = "${openstack_networking_subnet_v2.private-terraform-subnet.id}"
}


resource "openstack_compute_instance_v2" "ubuntu-terraform" {
  name = "ubuntu-vm-terraform"
  image_id = "1b09e165-fc5b-49cb-870c-6c45998ca323" #ubuntu 18.04
  flavor_id = "5d374029-989a-4335-b0dc-49b87cc0d83f" #m1.semi
  key_pair        = "keypair-tenant"
  security_groups = ["sg-vm-tenant"]

  network {
    name = "${openstack_networking_network_v2.private-terraform.name}"
  }
}

resource "openstack_networking_floatingip_v2" "fip-terraform" {
  pool = "provider"
}

resource "openstack_compute_floatingip_associate_v2" "fip-terraform-associate" {
  floating_ip = "${openstack_networking_floatingip_v2.fip-terraform.address}"
  instance_id = "${openstack_compute_instance_v2.ubuntu-terraform.id}"
}
