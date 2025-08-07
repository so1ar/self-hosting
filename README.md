# 树莓派自建服务

同样我习惯创建两个 docker 网络，frontend 用来对外开放端口，backend 不对外开放端口，如果网络有 ipv6 地址，也可以为 frontend 网络开启 ipv6 支持，以获得更快的 BT 下载速度。

```shell
docker network create --ipv6 frontend
docker netwrok create backend
```
