此目录为 openvpn 的 tap 模式配置文件目录

安装流程: 

  1. 参考教程 http://www.emaculation.com/doku.php/bridged_openvpn_server_setup
    首先按照这个教程一步一步走， 大部分系统无需编译安装，直接 apt install openvpn 即可，
    直接从 OpenVPN Server Setup 这个章节向下度，基本上是每一条命令都要执行的。

  2. 安装完成后，你发现你可以连接上 vpn ，但是只能 ping 通 vpn 服务器的 ip，
    内网内的其他主机是 ping 不同的，这个时候，请参考此文件夹里的配置文件即可。

  3. 关于安装完成后，如何用命令行生成客户端证书，在官方教程中，有一条命令把所需文件都
    帮你复制到了一个文件夹中，然后你只需要参考本文件中的 client.ovpn 即可。

  4. 修改  `/lib/systemd/system/openvpn@service`， 加入两句话，
    参考 本目录下的同名文件。

  5. openvpn-bridge 放置在 /etc/openvpn 目录中，权限 770

  6. server.conf 放置在 /etc/openvpn 目录中

  备注： openvpn 没有装载 树莓派上面，放在了 虚拟机上，虚拟机桥接网络,
  因为怕clash 的转发规则和vpn冲突，有时间了试试可以不可以合二为一。

关于 tun 模式：

  个人感觉 tun 模式比较简单，树莓派可以直接使用 pivpn
  默认安装方式就是 tun 模式，开箱即用




  https://github.com/pivpn/pivpn/issues/45


  tap 模式可以连接家里的打印机，可以实现 itunes server ,
  不过现在由于苹果系统更新了，所群晖已经fork-daapd 都无法
  使用。

  解决方法： nfs 挂载后，把 apple 设置里的，复制到资源库删掉，
  这样扫描一遍文件，它就不会复制到资料库。

  tap 模式，你可以在家里连接你在其他地方的电脑，就犹如它从很远的地方跟你一样连接了一个wifi。



## 路由分流

参考配置文件

[OpenVPN客户端添加路由配置（流量分流）](https://www.xxshell.com/1760.html)

