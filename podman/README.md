# 剧集与电影监控

使用 podman 运行在本地 Linux PC 上，Sonarr 用来监控剧集，Radarr 用来监控电影，Qbittorrent 作为下载客户端。

全部使用的是 linuxserver.io 的容器镜像，将 `*.container` 文件复制到 `/etc/container/systemd/` 文件夹下，运行 `sudo systemctl daemon-reload`，之后容器便可以以 systemd 服务的形式启动，比如 `sudo systmectl start qbittorrent-lsio.service` 启动 Qbittorrent。若想以非 root 用户运行（即 rootless 模式），就需要把文件复制到对应用户家目录的 `~/.config/container/systemd`，rootless 模式下的容器部分功能会受限制。

另外需要注意，用这种方式生成的 systemd 服务，无法 enable 或 disable，默认就是 enable 开机自启状态的，若不想要开机自启，需要删掉 container 文件中最后两行 [install] 部分

需要按照个人情况修改文件系统映射，以及用户的 uid 与 gid，另外 Qbittorrent 的做种端口 `TORRENTING_PORT` 建议自行修改为一个五位数的不常用端口，而且要一并修改对应的端口映射。

***映射的文件夹需要提前手动创建，不然会报错，另外由于红帽系发行版的 selinux 限制，需要在映射的文件夹后加个 `:z` 参数，不然容器会没有文件夹的读写权限***

***要想使 Sonarr 和 Radarr 的硬链接功能可用，对容器的文件系统映射有一定要求，具体可以参考[这里](https://trash-guides.info/Hardlinks/How-to-setup-for/Docker/)。***
