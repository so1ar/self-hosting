# Watchtower 自动更新容器

若想使用 Gotify 通知，需要在 `.env` 文件里填入 Gotify 的 url 和 token，如果 Gotify 和 Watchtower 运行在同一台服务器上，并且在同一个 docker 网络中，可以把 url 写成 `http://gotify`，并添加一个环境变量 `WATCHTOWER_NOTIFICATION_GOTIFY_TLS_SKIP_VERIFY=true`。

更多配置项可以看[这里](https://containrrr.dev/watchtower/arguments/)。
