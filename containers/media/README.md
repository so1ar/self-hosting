# 媒体管理

Sonarr 管理剧集，Radarr 管理电影，Bazarr 负责管理字幕，Qbittorrent 负责下载公开 BT 站的种子，Transmission 负责下载私有 PT 站的种子，PeerBanHelper 负责封禁 BT 吸血客户端。

`qb.sh` 脚本（在 Sonarr 和 Radarr 容器内被映射为了 `/usr/local/bin/qb`）可以在抓取种子时自动为 Qbittorrent 添加 Tracker，以增加下载速度。

我已经把需要修改的变量放在了 `.env` 文件里了：

- `MEDIA_DIR` 是用来存放下载文件的路径，这个路径在所有容器中的映射应该是完全相同的，修改这个变量会同时修改所有容器的路径映射；

- `QB_TORRENTING_PORT` 是 Qbittorrent 做种的端口，`TR_TORRENTING_PORT` 是 Transmission 做种的端口，运营商有可能封禁默认的端口，所以需要指定一个不同的端口，最好使用随机数生成器生成一个五位数的不常用端口；

- `TR_USER` 和 `TR_PASS` 是 Transmission 网页面板的用户名和密码，不指定的话 Transmission 就无需登录直接能打开；

- `TRANSMISSION_WEB_HOME` 是可选的 Transmission 自定义 WEBUI 路径，需要自行下载第三方 WEBUI 并制定路径；

- `PUID` 和 `PGID` 是宿主系统当前用户和用户组的 id，可以通过运行 `id` 命令查看当前的 id，一般都是 1000；

- `TZ` 是时区，按需修改即可。
