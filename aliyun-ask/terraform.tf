variable "name" {
  default = "demo-k8s"
}

data "alicloud_zones" "default" {
  available_resource_creation = "VSwitch"
}

resource "alicloud_vpc" "default" {
  vpc_name       = var.name
  cidr_block = "10.1.0.0/21"
}

resource "alicloud_vswitch" "default" {
  vswitch_name      = var.name
  vpc_id            = alicloud_vpc.default.id
  cidr_block        = "10.1.1.0/24"
  zone_id           = data.alicloud_zones.default.zones[0].id
}

resource "alicloud_cs_serverless_kubernetes" "serverless" {
  name_prefix                    = var.name
#  version                        = 1.16
  vpc_id                         = alicloud_vpc.default.id
  vswitch_ids                    = [alicloud_vswitch.default.id]
  new_nat_gateway                = true
  endpoint_public_access_enabled = true
  private_zone                   = false
  deletion_protection            = false
  kube_config                    = "/tmp/demo-k8s/config"
  client_cert                    = "/tmp/demo-k8s/client-cert.pem"
  client_key                     = "/tmp/demo-k8s/client-key.pem"
  cluster_ca_cert                = "/tmp/demo-k8s/cluster-ca-cert.pem"
  tags = {
    "env" = "dev"
    "name" = "demo-k8s"
  }
}

