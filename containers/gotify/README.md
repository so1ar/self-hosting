# Gotify 消息推送服务

需要在 `.env` 文件里填上管理员账户 admin 的密码，如果不填密码，默认的密码是 adminadmin，也可以在部署完成后在网页端修改密码；

如果运行在 Traefik 反向代理后面，需要在 compose 文件里的 lables 部分把域名改成自己的，并将环境变量 `GOTIFY_SERVER_TRUSTEDPROXIES` 设置为 Traefik 的 ip 或 ip 段，不然在日志中无法显示真实的客户端 ip；

如果想要用 Crowdsec 读取 Gotify 的日志，需要使用本目录内的 `Dockerfile` 构建新的镜像，并在 compose 文件里修改镜像 tag 为自己创建的新镜像的 tag：
```shell
# 为镜像指定 tag 为 gotify/server:logger
docker build -t gotify/server:logger .
```

另外按照我个人的习惯，我会将日志存放在单独的 Docker 卷里，方便 Crowdsec 读取，所以要先创建对应的 docker 卷：
```shell
docker volume create gotify-log
```
