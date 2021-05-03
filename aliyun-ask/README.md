[TOC]

## 一、项目介绍

本项目适用于运维或开发者在日常工作或学习过程中需要快速搭建ASK（Aliyun Serverless Kubernetes）

，采用按需计费方式开通，使用完后务必清理资源，以免持续计费。本文档采用terraform在阿里云上搭建出ASK，其中创建的资源有：

```txt
1个VSwitch
1个VPC
1个EIP
1个ASK
```



## 二、前置条件

1、阿里云账号下必须 > 100 RMB 余额，否则创建提示余额不足

2、确保执行terraform的环境可以登录阿里云

3、开通弹性容器实例时，需要授予名称AliyunECIContainerGroupRole的系统默认角色给服务账号，配置指引：https://help.aliyun.com/document_detail/90794.html?spm=5176.21213303.J_6028563670.7.aee43edaD26fVF&scm=20140722.S_help%40%40%E6%96%87%E6%A1%A3%40%4090794._.OR_ser-RL_AliyunECIContainerGroupRole-ID_help%40%40%E6%96%87%E6%A1%A3%40%4090794-V_1-P0_0

4、创建AliyunECIContainerGroupRole角色，进入链接提示操作会自动创建
https://eci.console.aliyun.com/?spm=a2c4g.11186623.2.9.17e03bc71ej7uJ#/eci/cn-shenzhen/welcome

5、AliyunECIContainerGroupRole角色添加AliyunNATGatewayFullAccess权限

## 三、注意事项

注意！！注意！！注意！！使用完资源后务必清理资源，以免资源保留导致持续扣费



## 四、资源计费

按需计费的资源是以小时维度进行计费，其中vpc、vsw、sg网络和策略相关的资源不收费，eip、ecs资源收费，费用可参考：

| 资源 | 链接                                                         |
| ---- | ------------------------------------------------------------ |
| ask  | https://help.aliyun.com/document_detail/86759.html?spm=a2c4g.11186623.6.655.19d2200an4b8JV#title-d8s-1gj-f9l |
| eip  | https://help.aliyun.com/document_detail/72142.html?spm=5176.11182188.0.dexternal.79c397e6nfn6Nx |



## 五、创建步骤

### 1、安装terraform

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
https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/cs_serverless_kubernetes#version
```
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
  version                        = 1.18
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

# 把kubeconfig、证书文件拷贝到~/.kube目录
mv /tmp/demo-k8s ~/.kube/

# 测试连接集群
kubectl --kubeconfig ~/.kube/demo-k8s/config get ns
```

输出以下信息为创建成功

```shell
alicloud_vpc.default: Creating...
alicloud_vpc.default: Creation complete after 6s [id=vpc-wz9nesoym12i57ykrn0bq]
alicloud_vswitch.default: Creating...
alicloud_vswitch.default: Creation complete after 6s [id=vsw-wz9hm32v02ray7nw8u5lz]
alicloud_cs_serverless_kubernetes.serverless: Creating...
alicloud_cs_serverless_kubernetes.serverless: Still creating... [10s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [20s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [30s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [40s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [50s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [1m0s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [1m10s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [1m20s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [1m30s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [1m40s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [1m50s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [2m0s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [2m10s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [2m20s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [2m30s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [2m40s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [2m50s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [3m0s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [3m10s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [3m20s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [3m30s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still creating... [3m40s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Creation complete after 3m45s [id=c0cf7ecafce0d41879f0ab79cfd230789]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```



### 3、清理资源

```shell
# 如不成功，命令可以多执行几次
▶ terraform destroy --force
```

输出以下信息为清理成功

```
alicloud_cs_serverless_kubernetes.serverless: Destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 10s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 20s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 30s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 40s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 50s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 1m0s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 1m10s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 1m20s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 1m30s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 1m40s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 1m50s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 2m0s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 2m10s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 2m20s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 2m30s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 2m40s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 2m50s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 3m0s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 3m10s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 3m20s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 3m30s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Still destroying... [id=c0cf7ecafce0d41879f0ab79cfd230789, 3m40s elapsed]
alicloud_cs_serverless_kubernetes.serverless: Destruction complete after 3m45s
alicloud_vswitch.default: Destroying... [id=vsw-wz9hm32v02ray7nw8u5lz]
alicloud_vswitch.default: Destruction complete after 6s
alicloud_vpc.default: Destroying... [id=vpc-wz9nesoym12i57ykrn0bq]
alicloud_vpc.default: Destruction complete after 5s

Destroy complete! Resources: 3 destroyed.
```

