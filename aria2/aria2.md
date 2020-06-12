aria2 是一款远程下载工具，首先需要在终端安装方法： 

```shell
sudo apt-get update -y

sudo apt-get install -y aria2

```

[安装参考](https://zoomadmin.com/HowToInstall/UbuntuPackage/aria2)

如果使用 Docker 则无需在本机安装 aria2 。

下面叙述 Docker 安装的方法：

[可以参考这个](https://github.com/wahyd4/aria2-ariang-docker)

树莓派选择 arm32 的版本，安装完成之后，只剩下端口映射之类的设置了。由于这个文档在这块写的不是很清楚，所以文件同级目录下有 shell 脚本文件，只需要 

`sh aria.sh` 即可开启docker。

然后访问 `ip:8123` 即可访问到。

```shell
  -v /root/.config/filebrowser/filebrowser.db:/app/filebrowser.db \
  -v /root/usb_data/Download:/data \
  -v /root/.config/aria2:/app/conf \
```

这里挂载了三个目录，分别是 filebrower 的目录，这个可挂可不挂，挂了也就是可以保存下你在 filebrowser 里面的设置而已。

第二个是你下载的地方，如果写错的话，下载的内容就被放到 Docker 镜像里的某个目录里了。

第三个是 aria2 的配置文件目录，可以自定义一些配置。

重要的事情就是，安装这个之后，需要配置什么，直接使用第三个挂载配置，然后做好端口映射就可以了。