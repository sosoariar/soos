ubuntu 网络配置

<img src="https://typora-1301255375.cos.ap-shanghai.myqcloud.com/img/image-20220121215132864.png" alt="image-20220121215132864" style="zoom:50%;" />

```shell
sudo mv /etc/netplan/01-netloan-manager-all.yaml /etc/netplan/01-netloan-manager-all.yaml.bak

sudo vi /etc/netplan/01-network-manager-all.yaml

# Let NetworkManager manage all devices on this system
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    ens33:
            dhcp4: no
						# 这里填写静态 ip，网段和前面看到的网关 ip 一致即可
            addresses: [192.168.2.100/24]
						# 这里填写的 ip 就是前面 NAT 设置里的网关 ip
            gateway4: 192.168.2.2
            nameservers:
                    addresses: [8.8.8.8,8.8.4.4]

sudo netplan apply

```



关闭 sudo 命令每次输入密码

```shell
sudo visudo
# 找到   %sudo ALL=(ALL:ALL) ALL
# 修改为 %sudo ALL=(ALL:ALL) NOPASSWD:ALL
```



vim 

```shell
sudo apt-get update
sudo apt install vim
```

