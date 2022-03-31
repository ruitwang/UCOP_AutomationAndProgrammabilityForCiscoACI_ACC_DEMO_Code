terraform {
  required_providers {
    aci = {
        source = "CiscoDevNet/aci"
    }
    mso = {
        source = "CiscoDevNet/mso"
    }
  }
}

provider "aci" {
    url = var.aciurl
    username = var.aciuser
    password = var.acipassword
    insecure = true
}

# Tenant Definition
resource "aci_tenant" "terraform_demo1" {
  name = "terraform_demo1"
  description  = "tenant_for_terraform"
}

# Networking Definition
resource "aci_vrf" "vrf_1" {
  tenant_dn              = "${aci_tenant.terraform_demo1.id}"
  name                   = "vrf_1"
}

resource "aci_bridge_domain" "bd_1" {
  tenant_dn   = "${aci_tenant.terraform_demo1.id}"
  name        = "bd_1"
  description = "This bridge domain is created by terraform ACI provider"
  relation_fv_rs_ctx = "${aci_vrf.vrf_1.id}"
  mac         = "00:11:BD:F8:19:AA"
}

resource "aci_subnet" "demosubnet1" {
  parent_dn                           = aci_bridge_domain.bd_1.id
  ip                                  = "10.0.2.14/27"
  scope                               = ["private"]
  description                         = "This subject is created by terraform"
  ctrl                                = ["unspecified"]
  preferred                           = "no"
  virtual                             = "yes"
}

resource "aci_bridge_domain" "bd_2" {
  tenant_dn   = "${aci_tenant.terraform_demo1.id}"
  name        = "bd_2"
  description = "This bridge domain is created by terraform ACI provider"
  relation_fv_rs_ctx = "${aci_vrf.vrf_1.id}"
  mac         = "00:22:BD:F8:19:BB"
}

resource "aci_subnet" "demosubnet2" {
  parent_dn                           = aci_bridge_domain.bd_2.id
  ip                                  = "10.0.3.28/27"
  scope                               = ["private"]
  description                         = "This subject is created by terraform"
  ctrl                                = ["unspecified"]
  preferred                           = "no"
  virtual                             = "yes"
}

resource "aci_application_profile" "ap_1" {
  tenant_dn         = "${aci_tenant.terraform_demo1.id}"
  name              = "ap_1"
}


resource "aci_application_epg" "epg_1" {
  application_profile_dn = "${aci_application_profile.ap_1.id}"
  name                   = "epg_1"
}

resource "aci_application_epg" "epg_2" {
  application_profile_dn = "${aci_application_profile.ap_1.id}"
  name                   = "epg_2"
}

resource "aci_contract" "contract_epg1_epg2" {
  tenant_dn = "${aci_tenant.terraform_demo1.id}"
  name      = "contract_epg1_epg2"
  description = "This contract is created by terraform ACI provider"
  scope       = "context"
  target_dscp = "VA"
}

resource "aci_contract_subject" "demosubject" {
  contract_dn                   = aci_contract.contract_epg1_epg2.id
  name                          = "test_tf_subject"
  description                   = "This subject is created by terraform ACI provider"
  cons_match_t                  = "None"
  prio                          = "unspecified"
  prov_match_t                  = "None"
  rev_flt_ports                 = "no"
  target_dscp                   = "unspecified"
}

resource "aci_filter" "demofilter" {
  tenant_dn                      = aci_tenant.terraform_demo1.id
  name                           = "demofilter"
  description                    = "This filter is created by terraform ACI provider."
}

resource "aci_filter_entry" "demoentry" {
  filter_dn     = aci_filter.demofilter.id
  name          = "test"
  description   = "This entry is created by terraform ACI provider"
  apply_to_frag = "no"
  arp_opc       = "unspecified"
  d_from_port   = "80"
  d_to_port     = "80"
  ether_t       = "ip"
  icmpv4_t      = "unspecified"
  icmpv6_t      = "unspecified"
  match_dscp    = "AF11"
  prot          = "tcp"
  s_from_port   = "80"
  s_to_port     = "443"
  stateful      = "no"
  tcp_rules     = ["ack"]
}

resource "aci_epg_to_contract" "example_consumer" {
  application_epg_dn = aci_application_epg.epg_1.id
  contract_dn        = aci_contract.contract_epg1_epg2.id 
  contract_type      = "provider"
}


resource "aci_epg_to_contract" "example_provider" {
  application_epg_dn = aci_application_epg.epg_2.id
  contract_dn        = aci_contract.contract_epg1_epg2.id
  contract_type      = "consumer"
  prio = "level1"
}

resource "aci_epg_to_static_path" "example_binding" {
  application_epg_dn  = aci_application_epg.epg_1.id
  tdn  = "topology/pod-1/paths-101/pathep-[eth1/40]"
  annotation = "annotation"
  encap  = "vlan-1000"
  instr_imedcy = "lazy"
  mode  = "regular"
}
