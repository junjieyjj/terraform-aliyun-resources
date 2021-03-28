# terraform-aliyun-ecs-cluster
使用terraform快速在阿里云构建一个ECS集群测试环境



## 一、项目介绍

本项目适用于运维或开发者在日常工作或学习过程中需要快速搭建ECS集群环境

，采用按需计费方式开通，使用完后务必清理资源，以免持续计费。本文档采用terraform在阿里云上搭建出ECS集群，其中创建的资源有：

```txt
1个VPC
1个VSW
1个EIP
多个ECS（EIP挂载到第一个实例上，可通过公网访问）
多个云盘（系统盘和数据盘）
1个SG
```



## 二、前置条件

1、阿里云账号下必须 > 100 RMB 余额，否则创建提示余额不足

2、确保执行terraform的环境可以登录阿里云



### 三、注意事项

注意！！注意！！注意！！使用完资源后务必清理资源，以免资源保留导致持续扣费



## 四、资源计费

按需计费的资源是以小时维度进行计费，其中vpc、vsw、sg网络和策略相关的资源不收费，eip、ecs资源收费，费用可参考：

| 资源 | 链接                                                         |
| ---- | ------------------------------------------------------------ |
| ecs  | https://www.aliyun.com/price/product?spm=5176.13329450.home-cf.price.bf9d4df5CByDul#/ecs/detail |
| eip  | https://help.aliyun.com/document_detail/72142.html?spm=5176.11182188.0.dexternal.79c397e6nfn6Nx |
| 云盘 | https://help.aliyun.com/document_detail/179022.html?spm=a2c4g.11186623.6.563.28df7255Xdcr0B |



## 五、创建步骤

#### 1、安装terraform

1）登录 [Terraform官网](https://www.terraform.io/downloads.html) 下载适用于您的操作系统的程序包。

2）将程序包解压到/usr/local/bin。

如果将可执行文件解压到其他目录，按照以下方法为其定义全局路径：

- - Linux：参见 [在Linux系统定义全局路径](https://stackoverflow.com/questions/14637979/how-to-permanently-set-path-on-linux-unix)。
  - Windows：参见 [在Windows系统定义全局路径](https://stackoverflow.com/questions/1618280/where-can-i-set-path-to-make-exe-on-windows)。
  - Mac：参见 [在Mac系统定义全局路径](https://stackoverflow.com/questions/14637979/how-to-permanently-set-path-on-linux-unix)。

3）运行terraform验证路径配置。

命令运行后将显示可用的Terraform选项的列表，如下所示，表示安装完成。

```shell
username:~$ terraform
Usage: terraform [-version] [-help] <command> [args]
```

4）为提高权限管理的灵活性和安全性，建议您创建RAM用户，并为其授权。

- A. 登录 [RAM控制台](https://ram.console.aliyun.com/#/overview)。

- b. 创建名为Terraform的RAM用户，并为该用户创建AccessKey。具体步骤请参见[创建RAM用户](https://help.aliyun.com/document_detail/28637.htm#concept-gpm-ccf-xdb)。

- c. 为RAM用户授权。具体步骤请参见[为RAM用户授权](https://help.aliyun.com/document_detail/116146.htm#task-187800)。

1. 创建环境变量，用于存放身份认证信息。

```shell
export ALICLOUD_ACCESS_KEY="LTAIUrZCw3********"
export ALICLOUD_SECRET_KEY="zfwwWAMWIAiooj14GQ2*************"
export ALICLOUD_REGION="cn-shenzhen"
```



### 2、创建资源（变更资源）

参数配置

```
module "tf-instances" {  
 source                      = "alibaba/ecs-instance/alicloud"  
 # ECS创建的区域
 region                      = "cn-shenzhen"  
 # ECS实例数，根据需要调整
 number_of_instances         = "1"
 use_num_suffix              = true
 vswitch_id                  = alicloud_vswitch.vsw.id  
 group_ids                   = [alicloud_security_group.default.id]  
 # vpc中的私有ip地址，需根据实例数调整，如有多台必须填写多个
 private_ips                 = ["172.16.0.10"]  
 # 镜像的id，参考：https://ecs.console.aliyun.com/?spm=5176.8351553.favorites.decs.26f81991hKR7KS#/image/region/cn-qingdao/systemImageList
 image_ids                   = ["centos_7_9_x64_20G_alibase_20210128.vhd"]  
 instance_type               = "ecs.t6-c1m2.large"   
 internet_max_bandwidth_out  = 10
 associate_public_ip_address = false
 instance_name               = "k8s_instances_"  
 host_name                   = "k8s-instance-"  
 internet_charge_type        = "PayByTraffic"   
 # ECS root登录密码
 password                    = "xxxx" 
 # 系统盘类型，这里使用高效云盘
 system_disk_category        = "cloud_efficiency"  
 # 系统盘大小，单位Gb
 system_disk_size            = 20
 
 # 数据盘配置，如不需要数据盘可删除
 data_disks = [    
  {      
    category = "cloud_efficiency"      
    name     = "k8s_data_disk"   
    size     = "20"
  } 
 ]
}
```

执行命令

```shell
# 初始化加载模块
terraform init

# 资源新建或变更（交互式），如不成功，命令可以多执行几次
terraform apply
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
  
# 资源新建或变更（非交互式），如不成功，命令可以多执行几次
terraform apply --auto-approve
```

输出以下信息为创建成功

```shell
▶ terraform apply --auto-approve
alicloud_vpc.vpc: Refreshing state... [id=vpc-wz9otgq149i8iowoloso2]
alicloud_eip.this[0]: Refreshing state... [id=eip-wz98mot0ckp7ixh70vvue]
alicloud_vswitch.vsw: Refreshing state... [id=vsw-wz93u6jg57hj9oogwfi2m]
alicloud_security_group.default: Refreshing state... [id=sg-wz9f7l0ewiddariakrcd]
alicloud_security_group_rule.allow_all_tcp: Refreshing state... [id=sg-wz9f7l0ewiddariakrcd:ingress:tcp:1/65535:intranet:0.0.0.0/0:accept:1]
module.tf-instances.alicloud_instance.this[0]: Creating...
module.tf-instances.alicloud_instance.this[0]: Still creating... [10s elapsed]
module.tf-instances.alicloud_instance.this[0]: Still creating... [20s elapsed]
module.tf-instances.alicloud_instance.this[0]: Creation complete after 22s [id=i-wz9bzmrlbf0bzm17twz2]
alicloud_eip_association.this_ecs[0]: Creating...
alicloud_eip_association.this_ecs[0]: Still creating... [10s elapsed]
alicloud_eip_association.this_ecs[0]: Still creating... [20s elapsed]
alicloud_eip_association.this_ecs[0]: Still creating... [30s elapsed]
alicloud_eip_association.this_ecs[0]: Creation complete after 37s [id=eip-wz98mot0ckp7ixh70vvue:i-wz9bzmrlbf0bzm17twz2]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```



### 3、清理资源

```shell
# 如不成功，命令可以多执行几次
▶ terraform destroy --force
```

输出以下信息为清理成功

```
alicloud_eip_association.this_ecs[0]: Destroying... [id=eip-wz98mot0ckp7ixh70vvue:i-wz9bzmrlbf0bzm17twz2]
alicloud_security_group_rule.allow_all_tcp: Destroying... [id=sg-wz9f7l0ewiddariakrcd:ingress:tcp:1/65535:intranet:0.0.0.0/0:accept:1]
alicloud_security_group_rule.allow_all_tcp: Destruction complete after 1s
alicloud_eip_association.this_ecs[0]: Destruction complete after 5s
alicloud_eip.this[0]: Destroying... [id=eip-wz98mot0ckp7ixh70vvue]
module.tf-instances.alicloud_instance.this[0]: Destroying... [id=i-wz9bzmrlbf0bzm17twz2]
alicloud_eip.this[0]: Destruction complete after 0s
module.tf-instances.alicloud_instance.this[0]: Still destroying... [id=i-wz9bzmrlbf0bzm17twz2, 10s elapsed]
module.tf-instances.alicloud_instance.this[0]: Destruction complete after 11s
alicloud_vswitch.vsw: Destroying... [id=vsw-wz93u6jg57hj9oogwfi2m]
alicloud_security_group.default: Destroying... [id=sg-wz9f7l0ewiddariakrcd]
alicloud_security_group.default: Destruction complete after 9s
alicloud_vswitch.vsw: Still destroying... [id=vsw-wz93u6jg57hj9oogwfi2m, 10s elapsed]
alicloud_vswitch.vsw: Still destroying... [id=vsw-wz93u6jg57hj9oogwfi2m, 20s elapsed]
alicloud_vswitch.vsw: Destruction complete after 23s
alicloud_vpc.vpc: Destroying... [id=vpc-wz9otgq149i8iowoloso2]
alicloud_vpc.vpc: Destruction complete after 5s

Destroy complete! Resources: 7 destroyed.
```

