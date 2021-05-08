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
#  kube_config                    = "/d/Amway/code/terraform-aliyun-resources/aliyun-ask/key/config"
#  client_cert                    = "/d/Amway/code/terraform-aliyun-resources/aliyun-ask/key/client-cert.pem"
#  client_key                     = "/d/Amway/code/terraform-aliyun-resources/aliyun-ask/key/client-key.pem"
#  cluster_ca_cert                = "/d/Amway/code/terraform-aliyun-resources/aliyun-ask/key/cluster-ca-cert.pem"
  tags = {
    "env" = "dev"
    "name" = "demo-k8s"
  }
}

resource "alicloud_nas_file_system" "default" {
  protocol_type = "NFS"
  storage_type  = "Performance"
  description   = "ask-nas"
  encrypt_type  = "1"
}

resource "alicloud_nas_access_group" "default" {
  access_group_name        = "ask_access_group"
  access_group_type        = "Classic"
  description              = "ask-access-group"
}

resource "alicloud_nas_access_rule" "default" {
  access_group_name = alicloud_nas_access_group.default.access_group_name
  source_cidr_ip    = "10.1.0.0/21"
  rw_access_type    = "RDWR"
  user_access_type  = "no_squash"
  priority          = 1
}

resource "alicloud_nas_mount_target" "default" {
  file_system_id    = alicloud_nas_file_system.default.id
  access_group_name = alicloud_nas_access_group.default.access_group_name
  vswitch_id        = alicloud_vswitch.default.id
}
