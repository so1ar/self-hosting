# 我的 docker 自建服务

全部为 docker-compose.yml 文件，方便一键部署，具体配置项参考对应文件夹中的 README 文件。

我比较习惯创建两个网络，frontend 网络对外开放服务，并指定网段，backend 网络不对外开放：
```shell
docker network create frontend --subnet 172.25.0.0/24
docker network create backend
```
