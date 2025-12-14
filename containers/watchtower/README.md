# Watchtower 自动更新容器

**2025-12-14 更新，在最新版 Docker 中原版 Watchtowerr 已经不能用了，建议更换为正在积极维护的 Fork `nickfedor/watchtower`** 

若想使用 Gotify 通知，需要在 `.env` 文件里填入 Gotify 的 url 和 token，如果 Gotify 和 Watchtower 运行在同一台服务器上，并且在同一个 docker 网络中，可以把 url 写成 `http://gotify`，并添加一个环境变量 `WATCHTOWER_NOTIFICATION_GOTIFY_TLS_SKIP_VERIFY=true`。

更多配置项可以看[这里](https://watchtower.nickfedor.com)。
