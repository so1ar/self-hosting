# Vaultwarden 服务

本地开放 7080 端口，bruceforce/vaultwarden-backup 用来自动备份数据。

Vaultwarden 强制要求 https，需配合 Caddy 或其他 web 服务器使用，在 `docker-compose.yml` 文件里填上自己的域名，配置好 Caddy 后，打开浏览器进行初始化设置，设置完账户后，为了安全考虑，需要将 `SIGNUPS_ALLOWED` 改为 false，并重启容器，禁止新账户注册。

自动备份我个人配置了 gpg 加密，需要提供自己的公钥文件，假如文件名是 `PathToYourPublicKey.asc`，运行 `base64 -w 0 PathToYourPublicKey.asc` 转换为 base64 格式后填到 `.env` 文件里的 `ENCRYPTION_BASE64_GPG_KEY` 一项后面，更多的自动备份配置项可以看[这里](https://gitlab.com/1O/vaultwarden-backup)。
