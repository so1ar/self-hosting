# Jackett 和 Flaresolverr 服务

用来为 Sonarr 和 Radarr 提供种子下载源。

Jackett 在本地开放 9117 端口，Flaresolverr 未对外开放端口。

在 Jackett 设置里，需将 `FlareSolverr API URL` 设置为 `http://flaresolverr:8191`。

`docker-compose.yml` 里面 PUID 和 PGID 两个环境变量需要填当前用户的 uid 和 gid，可以在终端运行 `id` 来查看，如果只配置了一个普通用户，那大概率就是 1000。
