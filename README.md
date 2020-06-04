# RaspberryPi4B

树莓派4b 配置及部署

1. 安装系统:
    简而言之：官网下载写镜像软件，下载镜像并写入内存卡， 开机。
2. 图形页面开启 SSH 服务，然后关闭图形化显示界面, 选择 cli
3. clash 安装及部署
4. ddns 地址： https://registry.hub.docker.com/r/sanjusss/aliyun-ddns/
5. Docker 安装（注意某些x86镜像无法在树莓派上面跑，需要重新编译镜像）
6. 配置 nginx， 配置最好放置在 `/etc/nginx/conf.d/` 目录下，如 blog.conf、upstream.conf、ycad.conf
7. 配置 webhook 端口 18081 容器内端口 10024





## clash 旁路由

clash 可以通过**透明代理**实现旁路由，完美扶墙。

* 重点：

  *  实现旁路由必须开启 **透明代理** 。配置中加入 `redir-port: 7892` , 如果手动设置代理，是不需要开启透明代理的。

  * 树莓派设置静态ip，不过不设置一般也不会变，设置了好一些。

  * 默认配置文件中 7890 是 http 端口， 7891 是 socks 端口。如果开启了透明代理是 7892 端口。

  * 如果不是使用透明代理，需要手动设置其他设备的网络代理才能上网。

  * 开机自动启动配合 pm2 。

    ```shell
    sudo pm2 start clash -- -d /home/pi/.config/clash
    sudo pm2 save
    sudo pm2 startup
    ```

  * **DNS监听53端口** ： 如果开启的时候，发现日志 53 端口没有权限，需要使用 sudo 来开启，否则无法正常开启 DNS 转发服务。

  * 默认配置文件在 ~/.config/clash。如果是 sudo 执行的，那么它默认回去 /home/root/.config/clash 寻找配置文件，所以如果你的配置文件放在 /home/pi/.config/clash ，使用 sudo 启动的时候，需要手动指定配置文件地址。

    ```shell
    sudo pm2 start clash -d /home/pi/.config/clash
    ```

  * clash 中 DNS 模式设定可以根据自己的需求进行设定。其中 dns 可以自行更改。另一方面，其实 DNS 可以指向主路由，然后在主路由做一些防污染的设置。关于 DNS 这里我没有深入研究，有时间再去研究。

    ```ymal
    dns:
      enable: true
      listen: 0.0.0.0:53
      enhanced-mode: redir-host
      nameserver:
      - 223.5.5.5
      - 119.29.29.29
      fallback:
      - tls://1.1.1.1:853
      - tls://1.0.0.1:853
      - tls://9.9.9.9:853
    ```

  * Doh: 解释全称 DNS-over-HTTPS 

  * 为使用的设备终端配置代理服务器

    ```shell
    # Define `setproxy` command to enable proxy configuration
    setproxy() {
      export http_proxy="http://localhost:8888"
      export https_proxy="http://localhost:8888"
    }
    
    # Define `unsetproxy` command to disable proxy configuration
    unsetproxy() {
      unset http_proxy
      unset https_proxy
    }
    
    # By default, enable proxy configuration for terminal login
    setproxy
    ```

    使用方法： `setproxy` 执行 开启 代理， unsetproxy 执行关闭代理

  * 开启ip转发编辑 /etc/sysctl.conf 文件，将 `net.ipv4.ip_forward=0` 修改为 `net.ipv4.ip_forward=1`，然后执行 `sysctl -p` 以使配置生效。

  * 旁路由其他模式，如 tun 模式，详情见参考

  * 开机自动启动参考下面章节PM2

  * 我目前使用的是 nftables 版本的规则，并没有使用 iptables ，因为 iptables 貌似在我机器上有些问题。

    新建两个文件：

    1. 私有地址定义文件（私有地址不走代理）

       ```yaml
       define private_list = {
       	0.0.0.0/8,
       	10.0.0.0/8,
       	127.0.0.0/8,
       	169.254.0.0/16,
       	172.16.0.0/12,
       	192.168.0.0/16,
       	224.0.0.0/4,
       	240.0.0.0/4
       }
       ```

    2. 主配置文件，我放在了 `/etc/nftables.conf`

       ```yaml
       #!/usr/sbin/nft -f
       
       include "/etc/nftables/private.nft"
       
       table ip nat {
       	chain proxy {
       		ip daddr $private_list return
       			ip protocol tcp redirect to :7892
       	}
       	chain prerouting {
       		type nat hook prerouting priority 0; policy accept;
       		jump proxy
       	}
       }
       ```

       常用命令：

       `sudo nft flush ruleset`  清空所有设置

       `sudo nft -f /etc/nftables.conf`  让设置生效

       `sudo sh -c "nft flush ruleset && nft -f /etc/nftables.conf"` 一条命令解决

       `sudo nft list ruleset`  查看 nftables 的状态

       `systemctl enable nftables.service`  设置开机启动

  * DNS优化问题：目前我还没遇到 DNS 体验不太好的地方，所以暂时没研究，不过以后遇到了可以参考

    [smartdns 来优化 DNS 服务](https://a-wing.top/network/2020/03/01/bypass_gateway-2_improve_dns.html)

  * YACD 前端管理工具: git clone 后，进行编译，然后移动 public/* 文件到 ~/.config/clash/dashboard 中，访问 http://ip:port/ui 即可。
  * 

  

  

* PM2 自动启动

  运行 `pm2 startup`，即在`/etc/init.d/`目录下生成`pm2-root`的启动脚本，且自动将`pm2-root`设为服务。

  运行 `pm2 save`，会将当前pm2所运行的应用保存在`/root/.pm2/dump.pm2`下，当开机重启时，运行`pm2-root`服务脚本，并且到`/root/.pm2/dump.pm2`下读取应用并启动。

* Clash-DNS 原理解释

  Clash DNS Clash 支持各种规则组进行分流，包括基于 DOMAIN 的规则。当通过 SOCKS5 和 HTTP 时 Clash 可以直接获取连接域名；但是直接将 TCP 流量重定向到 Clash 的 redir 端口时不能直接获取到连接域名，因为根据 TCP/IP 协议的特性，Application 在创建连接时会先发出一个 DNS 请求获取目标 IP，然后直接向 IP 发起连接。Clash 内置了一个 DNS Server 以反查 TCP 连接的域名，用于解析域名规则。 Clash 在 ChinaDNS 思路的基础上设计了国内外 DNS 分流的方法——Clash DNS 的上游分为两组 nameserver 和 fallback。Clash 首先同时向两组中所有 DNS 发起解析请求，然后从 nameserver 中选取解析返回最快的 IP；如果这个 IP 不属于 CN 时则采用 fallback 组中解析返回最快的 IP。这个 IP 将会用于解析 IP 规则、或者在直连时使用。 对于匹配到规则、而且规则指定了使用代理，连接会被发往远端的代理服务器；代理服务器拿到的是 Host 不是 IP，所以代理服务器会在远端进行 DNS 解析，只有在 DIRECT（直连）中才会使用 Clash DNS 解析的 IP 进行连接。这意味着除非需要 DIRECT，大部分情况下 Clash DNS 不需要得到最正确或是最佳的结果（有时甚至可以是被污染的 IP）——因为 Clash DNS 目的是为了解析规则、得到的 IP（你的 Application 以为连接的 IP）和代理服务器实际连接的 IP 很可能是不一样的。 redir-host 的问题 当 Clash DNS 以 redir-host 模式运行时，不仅需要反查域名解析分流规则，还需要把得到的 IP 返回给客户端、不论这个 IP 是否准确。虽然 Application 会认为自己要去连接到 Clash DNS 返回的 IP，但是 KoolClash 会把所有的连接使用 iptables 重定向到 Clash，一旦 Clash 将连接交给代理服务器、代理服务器会进行解析并拿到返回的内容。这不会影响任何正常上网、看视频，但在一些极端情况下会产生问题。比如在 Clash 的 issues#95 中讨论的，YouTube 的会被 DNS 污染到 243 开头的 IP，Clash DNS 不能处理保留 IP 并将其返回，而部分应用程序（如 Chrome）拒绝连接这个 IP（ERR_ADDRESS_UNREACHABLE）。 抛开 DNS 污染的问题，Chrome 和 Firefox 浏览器有 preconnect 特性、在浏览器拿到 IP 以后会试图直接与这个 IP 进行 TCP 握手。虽然建立 TCP 握手的开销很小，但是由于 Clash DNS 返回的这个 IP 和代理服务器在远端解析的 IP 可能不一样、甚至对应 IP 规则和域名规则所使用的代理服务器也不同，最后会产生不必要的开销。 fake-ip 来了 终于，Clash 在 0.14.0 版本推出了 fake-ip 模式。当 TCP 连接建立时，Clash DNS 会直接返回一个保留地址的 IP（即 Fake IP；Clash 默认使用 198.18.0.0/16，下文以此为例），同时 Clash 继续解析域名规则和 IP 规则。对于 KoolClash 来说，所有流量都被 iptables 转发给 Clash，Clash 会处理 Fake IP 额请求的域名之间的对应关系。 而且如果 Clash DNS 匹配到了域名规则、则不需要向上游 DNS 请求，Clash 已经可以直接将连接发给代理服务器，节省了 Clash DNS 向上游 DNS 请求解析。Application 拿到的是 Clash DNS 返回的 Fake IP，所以也不会出现某些应用程序拒绝连接一些 IP 的情况；和 redir-host 模式一样，在大部分情况下 fake-ip 模式下也可以完全无视 DNS 污染。 fake-ip 的问题 当 Clash 重启时，Fake IP 会重新从头开始分配；如果设备或软件缓存了 Clash 重启前解析的 Fake IP，可能会出现无法访问等问题。Clash 已经 dev 分支中将 TTL 修改为 1 以解决这个问题。 由于所有域名都被返回 Fake IP，意味着所有流量都必须经过 Clash 处理。这意味着使用 iptables 实现端口控制局域网 IP 绕行都会变得毫无意义。Clash 提供 SRC-IP-CIDR SRC-PORT 和 DST-PORT，有访问控制需求的用户需要自己编写 Clash 的配置文件。 KoolClash 的 Fake DNS KoolClash 之前将所有 DNS 请求通过 dnsmasq 全部转发给 Clash（Clash DNS 监听在 23453 端口上），结果在测试 fake-ip 时导致 Clash 在解析代理服务器的节点域名时都被解析到 Fake IP。 KoolClash 通过 iptables 将所有 198.19.0.0/24 中 53 端口的流量转发到 23453 端口上，并要求用户将需要联网设备的 DNS 修改为 198.19.0.1 和 198.19.0.2。这样路由器内部直接使用 53 端口通过 dnsmasq 直接进行解析，外部连接的设备的 DNS 请求发往 198.19.0.0/24 的 53 端口而被 iptables 拦截转发给 Clash，从而将路由器内部的 DNS 解析和需要使用 Clash DNS 的解析分开。KoolClash 将 198.19.0.0/24 称为 Fake DNS。 需要使用 KoolClash 的设备，除了需要将网关指向 KoolClash 所在的设备的 IP 以外，还需要修改 DNS 到 198.19.0.1 和 198.19.0.2；如果 DNS 依然指向网关，Clash 将不能解析域名规则，直连解析也可能会导致 DNS 污染；当停止使用 KoolClash 以后，需要还原设备的 DNS 设置。

  [原帖](https://blog.skk.moe/post/alternate-surge-koolclash-as-gateway/)





* 参考：

  [**openwrt主路由配合树莓派开设Clash透明代理简单记录**](https://www.right.com.cn/forum/thread-498937-1-1.html)

  [树莓派使用clash](https://ssu.tw/index.php/archives/37/)

  [clash旁路由使用tun模式](https://www.xzcblog.com/post-290.html)

  [自制旁路网关（一） ——使用clash做代理](https://a-wing.top/network/2020/02/22/bypass_gateway-1_clash.html)

  [使用Debian9自己打造一个旁路由](https://lala.im/5727.html)

  [在 Ubuntu18.04 上使用 clash 部署旁路代理网关（透明代理）](https://breakertt.moe/2019/08/20/clash_gateway/)

  [DNS污染对Clash（for Windows）的影响](https://github.com/Fndroid/clash_for_windows_pkg/wiki/DNS%E6%B1%A1%E6%9F%93%E5%AF%B9Clash%EF%BC%88for-Windows%EF%BC%89%E7%9A%84%E5%BD%B1%E5%93%8D)

  [透明代理/路由器翻墙· V2Ray 配置指南|V2Ray 白话文教程](https://github.com/Dreamacro/clash/issues/158)

  [Clash作为透明代理是否有意义？ ](https://github.com/Dreamacro/clash/issues/158)

  [规则模板V2RaySSR综合网](https://www.v2rayssr.com/clashxx.html?btwaf=33057920)

* 常用命令

  * route： 查看和操作IP路由表

  * netstat -rn : 显示路由表（某些没有 route 命令时使用）

  * lscpu : 查看树莓派架构信息

  * 树莓派防火墙相关:  

    安装: `sudo apt install ufw`

    启用/关闭: `sudo ufw enable/disable`

    状态: `sudo ufw status`

  * tcpdum 相关

    ```shell
    tcpdump -i eth1  # 监听指定接口
    
    tcpdump host ip # 监听指定主机流入和流出
    
    # 不同的规则之间用 and 或者 or 连接 ! 表示除了
    
    tcpdump -i eth0 src host hostname  # 监听hostname 发送的所有数据包
    
    tcpdump -i eth0 dst host hostname  # 监听发送到主机hostname的所有数据包
    
    tcpdump tcp port 23 and host hostname  # 监听TCP协议PORT为23主机为 hostname 的数据包
    
    tcpdump udp port 123  # 监听 udp 端口 123 的数据包
    
    # 监听指定网络的数据包
    
    tcpdump net ucb-ether  # 打印本地主机与Berkeley网络上的主机之间的所有通信数据包(nt: ucb-ether, 此处可理解为'Berkeley网络'的网络地址,此表达式最原始的含义可表达为: 打印网络地址为ucb-ether的所有数据包)
    
    tcpdump 'gateway snup and (port ftp or ftp-data)'  # 打印所有通过网关snup的ftp数据包(注意, 表达式被单引号括起来了, 这可以防止shell对其中的括号进行错误解析)
    
    tcpdump ip and not net localnet  # 打印所有源地址或目标地址是本地主机的IP数据包 (如果本地网络通过网关连到了另一网络, 则另一网络并不能算作本地网络.(nt: 此句翻译曲折,需补充).localnet 实际使用时要真正替换成本地网络的名字)
    
    ```

    [tcpdump 详解](https://www.cnblogs.com/ggjucheng/archive/2012/01/14/2322659.html)

  * 由于当时出现了一系列问题，所以上了 wireshark 进行抓包分析错误，发现一堆的 trasmission 错误，附上一些 wireshark 常见过滤规则

    * 关键字

      “与”：“eq” 和 “==”等同，可以使用 “and” 表示并且，

      “或”：“or”表示或者。

      “非”：“!" 和 "not” 都表示取反。

    * 针对ip的过滤
      针对wireshark最常用的自然是针对IP地址的过滤。其中有几种情况：

    　　（1）对源地址为192.168.0.1的包的过滤，即抓取源地址满足要求的包。

            表达式为：ip.src == 192.168.0.1

    　　（2）对目的地址为192.168.0.1的包的过滤，即抓取目的地址满足要求的包。

            表达式为：ip.dst == 192.168.0.1

    　　（3）对源或者目的地址为192.168.0.1的包的过滤，即抓取满足源或者目的地址的ip地址是192.168.0.1的包。

            表达式为：ip.addr == 192.168.0.1,本表达式的等价表达式为

     ip.src == 192.168.0.1or ip.dst == 192.168.0.1

    　　（4）要排除以上的数据包，我们只需要将其用括号囊括，然后使用 "!" 即可。

            表达式为：!(表达式)
    * 针对协议过滤

      （1）仅仅需要捕获某种协议的数据包，表达式很简单仅仅需要把协议的名字输入即可。

                     表达式为：http
          
                     问题：是否区分大小写？答：区分，只能为小写

      　　（2）需要捕获多种协议的数据包，也只需对协议进行逻辑组合即可。

              表达式为：http or telnet （多种协议加上逻辑符号的组合即可）

      　　（3）排除某种协议的数据包

              表达式为：not arp   或者   !tcp

    * 根据端口过滤

      　　（1）捕获某一端口的数据包

      ​    表达式为：tcp.port == 80 （以tcp协议为例）

      　　（2）捕获多端口的数据包，可以使用and来连接，下面是捕获高于某端口的表达式

      ​    表达式为：udp.port >= 2048 （以udp协议为例）



## 2020.5.29 补充

clash 使用了两周左右了，目前看来十分稳定，并且怀疑以前在路由器上每次并不是节点的问题，而是路由器的问题。 再想了一下，觉得买个 ac86u 感觉十分没有必要了， 八百多块钱，毕竟还是一个路由器，不如 这个树莓派能做的事情多。

其次，SSH 从外网连接进来发生了问题。 某天，在公司想连接树莓派，ssh 一连就上，因为路由已经端口转发了，直接转发到了这个树莓派上面。但是，奇怪的是，路由上的其他服务器却连不上了。

其中： 苹果的远程连接(VNC)，无法连接， 通过 wireshark 及 tcpdump 抓包，发现了很多 reset 包，稍微分析了一下，应该因为 路由器设置了端口转发，直接将外网的流量转发到了 我的另一台 linux 服务器上，但是 linux 此时的网关是指向树莓派的，而树莓派是走了透明代理，应该是对数据包做了一些处理，最终源主机发现数据不对劲，就一直发送重连请求。 

解决方法： 原来设置 外网端口 转发 linux服务器 22 端口，现在设置 路由器 转发 树莓派的 某个端口，然后 树莓派上面设置 iptables 规则，将这个端口的数据再转发到目标 linux 主机对应的端口上 即可。因为 树莓派已经作为一个网关设备了，所以不需要写 linux 服务器流量入口转发规则。

```
iptables -t nat -A PREROUTING -d 192.168.123.2 -p tcp --dport 10600 -j DNAT --to-destination 192.168.123.8:22

```

解释一下，将 192.168.132.2 的 10600 端口的流量转发至 192.168.123.8 的 22 端口上。



## 挂载移动硬盘

```shell
sudo fdisk -l   # 查看状态

sudo mkdir /home/pi/usb_data   # 创建希望挂载到的目录

sudo aptitude install ntfs-3g   # NTFS 需要安装这个软件

modprobe fuse  # 加载 内核模块

# 手动挂载, 注意修改 sda1 为你的移动硬盘
sudo mount /dev/sda1  /home/pi/usb_data

sudo vim /etc/fstab  # 移动硬盘开机自动挂载

在上面打开的文件中写入下面这句话, 注意修改 sda1 为你的移动硬盘
/dev/sda1  /home/pi/usb_data ntfs-3g defaults,noexec,umask=0000 0 0

## 下面是 exFat 格式硬盘的挂载方式

sudo apt-get install exfat-fuse  # 安装支持软件

# 手动挂载, 注意修改 sda1 为你的移动硬盘
sudo mount /dev/sda1  /home/pi/usb_data



# 如果要添加开启自动挂载，请编辑 /ect/fstab 文件
# 加入，注意修改 sda1 为你的 移动硬盘
/dev/sda1 /mnt/usbdisk vfat rw,defaults 0 0

```

[参考树莓派之挂载移动硬盘](https://www.jianshu.com/p/ef23a1b88c22)

帖子上面说需要外置电源，目前我是树莓派4b，还没有发现不适，暂时还没有外接电源。



## 2020-5.31 更新

周末闲来无事，又摆弄了一番，发现一些安全问题，系统无法及时更新，所以还是不要暴露公网端口较好。

配置了 OpenVPN， 内网所有流量都走 VPN 来转发，目前对外只保留必要端口，如 80、443。

关于 OpenVPN 的配置有时间在更新。

## 2020-6-3 更新

使用 tun 模式，发现其实是相当于又划分了一个子网， 连接 了vpn 的设备可以访问其他设备，
其他设备无法访问 vpn 设备，并且我主要是有个需求， itunes server 无法广播到 我使用
vpn 的这台主机， 然后就弃用了。

更换  tap 模式， tap 基于二层协议打通隧道，可以和vpn服务器所在网络在同一个子网，这样就可以接收到广播包了，
也就可以正常使用 itunes server 的工具了，连上vpn后，和家里的设备连接家里的路由器效果一样，就相当于都在
同一个子网。
