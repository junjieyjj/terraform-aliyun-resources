provider "alicloud" {
}

variable "k8s_name_prefix" {
  description = "The name prefix used to create managed kubernetes cluster."
  default     = "demo-ack"
}

resource "random_uuid" "this" {}

# 默认资源名称。
locals {
  k8s_name     = substr(join("-", [var.k8s_name_prefix, random_uuid.this.result]), 0, 63)
  new_vpc_name = "vpc-for-${local.k8s_name}"
  new_vsw_name = "vsw-for-${local.k8s_name}"
  log_project_name = "log-for-${local.k8s_name}"
}

# 节点ECS实例配置。
data "alicloud_instance_types" "default" {
  cpu_core_count       = 2
  memory_size          = 4
  kubernetes_node_role = "Worker"
}

// 满足实例规格的AZ。
data "alicloud_zones" "default" {
  available_instance_type = data.alicloud_instance_types.default.instance_types[0].id
}

# 专有网络。
resource "alicloud_vpc" "default" {
  vpc_name       = local.new_vpc_name
  cidr_block     = "10.1.0.0/21"
}

# 交换机。
resource "alicloud_vswitch" "vswitches" {
  vswitch_name      = local.new_vsw_name
  vpc_id            = alicloud_vpc.default.id
  cidr_block        = "10.1.1.0/24"
  zone_id = data.alicloud_zones.default.zones[0].id
}

# 附加配置
variable "cluster_addons" {
  type = list(object({
    name      = string
    config    = string
  }))
  default = [
    {
      "name"     = "logtail-ds",
      "config"   = "{\"IngressDashboardEnabled\":\"true\",\"sls_project_name\":alicloud_log_project.log.name}",
    },
    {
      "name"     = "nginx-ingress-controller",
      "config"   = "{\"IngressSlbNetworkType\":\"internet\"}",
    },
    {
      "name"     = "flannel",
      "config"   = "",
    },
    {
      "name"     = "csi-plugin",
      "config"   = "",
    },
    {
      "name"     = "csi-provisioner",
      "config"   = "",
    } 
  ]
}

# Kubernetes托管版。
resource "alicloud_cs_managed_kubernetes" "default" {
  name                      = local.k8s_name
  worker_vswitch_ids        = split(",", join(",", alicloud_vswitch.vswitches.*.id))
  version                   = "1.20.11-aliyun.1"
  new_nat_gateway           = true
  worker_instance_types     = [data.alicloud_instance_types.default.instance_types[0].id]
  worker_number             = 2
  password                  = "1qaz@WSXp@ssword"
  # pod网络的CIDR块。当cluster_network_type设置为flannel，你必须设定该参数。它不能与VPC CIDR相同，并且不能与VPC中的Kubernetes群集使用的CIDR相同，也不能在创建后进行修改。群集中允许的最大主机数量：256。
  pod_cidr                  = "172.20.0.0/16"
  # 服务网络的CIDR块。它不能与VPC CIDR相同，不能与VPC中的Kubernetes群集使用的CIDR相同，也不能在创建后进行修改。
  service_cidr              = "172.21.0.0/20"
  # 是否为kubernetes的节点安装云监控。
  install_cloud_monitor     = true
  # 是否为API Server创建Internet负载均衡。默认为false。
  slb_internet_enabled      = true
  # slb的实例类型
  load_balancer_spec        = "slb.s1.small"
  # 网络模式
  proxy_mode                = "ipvs"
  # 节点的系统磁盘类别。其有效值为cloud_ssd和cloud_efficiency。默认为cloud_efficiency。
  worker_disk_category      = "cloud_efficiency"
  # 节点的数据磁盘类别。其有效值为cloud_ssd和cloud_efficiency，如果未设置，将不会创建数据磁盘。
  worker_data_disk_category = "cloud_efficiency"
  # 节点的数据磁盘大小。有效值范围[20〜32768]，以GB为单位。当worker_data_disk_category被呈现，则默认为40。
  worker_data_disk_size     = 20
  # 附加配置
  dynamic "addons" {
      for_each = var.cluster_addons
      content {
        name          = lookup(addons.value, "name", var.cluster_addons)
        config        = lookup(addons.value, "config", var.cluster_addons)
      }
  }
}