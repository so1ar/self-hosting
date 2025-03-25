# Traefik 与 Authelia 配置

Traefik 需要从 DNS 提供商处获取 api 密钥，并配置好自己的域名。

Authelia 需要根据自己需要配置好域名、用户名与密码等，并创建三个高强度密码填入 `authelia/secrets/` 的三个文件中。
