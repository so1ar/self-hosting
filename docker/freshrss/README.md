# FreshRSS 和 RSSHub 服务

FreshRSS 在本地开放了 8080 端口，有需要自行修改，RSSHub 没有开放外部端口，只有 FreshRSS 容器可访问 RSSHub 的 1200 端口。

如果要开放到公网，需要修改 `.env` 文件里的邮箱和域名，并配置好 Caddy 反向代理。

在 FreshRSS 内添加 RSSHub 路由时，只需使用 `http://rsshub:1200`，如 `http://rsshub:1200/sspai/matrix` 便可订阅少数派 Matrix 更新。

如有其他 RSSHub 相关的配置也可添加到里面，具体参看[这里](https://docs.rsshub.app/zh/deploy/config#%E9%85%8D%E7%BD%AE)
