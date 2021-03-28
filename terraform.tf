provider "alicloud" {}

resource "alicloud_vpc" "vpc" {
  vpc_name   = "tf_k8s"
  cidr_block = "172.16.0.0/12"
}

resource "alicloud_vswitch" "vsw" {
  vpc_id            = alicloud_vpc.vpc.id
  cidr_block        = "172.16.0.0/21"
  zone_id = "cn-shenzhen-d"
}

resource "alicloud_security_group" "default" {
  name   = "default"
  vpc_id = alicloud_vpc.vpc.id
}

resource "alicloud_security_group_rule" "allow_all_tcp" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "1/65535"
  priority          = 1
  security_group_id = alicloud_security_group.default.id
  cidr_ip           = "0.0.0.0/0"
}

module "tf-instances" {  
 source                      = "alibaba/ecs-instance/alicloud"  
 region                      = "cn-shenzhen"  
 number_of_instances         = "1"  
 use_num_suffix              = true
 vswitch_id                  = alicloud_vswitch.vsw.id  
 group_ids                   = [alicloud_security_group.default.id]  
 private_ips                 = ["172.16.0.10"]  
 image_ids                   = ["centos_7_9_x64_20G_alibase_20210128.vhd"]  
 instance_type               = "ecs.t6-c1m2.large"   
 internet_max_bandwidth_out  = 10
 associate_public_ip_address = false
 instance_name               = "k8s_instances_"  
 host_name                   = "k8s-instance-"  
 internet_charge_type        = "PayByTraffic"   
 password                    = "Admin@123" 
 system_disk_category        = "cloud_efficiency"  
 system_disk_size            = 20
 
 data_disks = [    
  {      
    category = "cloud_efficiency"      
    name     = "k8s_data_disk"   
    size     = "20"
  } 
 ]
}

resource "alicloud_eip" "this" {
  count = 1
  bandwidth = 10
}

resource "alicloud_eip_association" "this_ecs" {
  count = 1
  instance_id   = module.tf-instances.this_instance_id[0]
  allocation_id = alicloud_eip.this[0].id
}
