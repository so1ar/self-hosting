# Caddy web 服务器

用以反向代理将服务开放到公网，或是运行其他 web 服务。

## 使用方式

编辑 `docker-compose.yml` 文件，将其中的 email 改为自己的邮箱地址，以便自动续期 ssl 证书，如果有其他必要的文件，也记得要映射进容器里面，再将对应的站点配置文件写入 `Caddyfile` 里面。

`Caddyfile` 里已经有了一个 Vaultwarden docker 反代的示例配置。
