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

