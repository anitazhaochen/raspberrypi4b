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





  https://github.com/pivpn/pivpn/issues/45
