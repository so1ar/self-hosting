#!/bin/bash

#### 开始配置

# 自建 Gotify 的 url
GOTIFY_URL=https://gotify.example.com
# Gotify 的 token
GOTIFY_TOKEN=SuperSecretToken

# FreshRSS 的项目路径
FRESHRSS_DIR=/home/user/containers/freshrss
# 备份路径
BACKUP_DIR=/home/user/backup

#### 结束配置

# 创建临时文件夹
mkdir /tmp/backup
cd /tmp/backup

# 显示备份时间
time=$(date +%Y-%m-%d-%H%M)

# 停止容器
docker stop freshrss >> /dev/null

# 开始备份 FreshRSS
tar -czf FreshRSS-backup-${time}.tgz -C ${FRESHRSS_DIR} .

# 加密文件，需要改成自己的公钥
gpg --recipient so1ar --encrypt FreshRSS-backup-${time}.tgz

# 将加密后的文件移动到备份文件夹
mv FreshRSS-backup-${time}.tgz.gpg ${BACKUP_DIR}/freshrss/

# 删除早于十天的文件
find ${BACKUP_DIR}/freshrss/ -mtime +5 -name "*.*" -exec rm -rf {} \;

# 重新启动容器
docker start freshrss >> /dev/null

# 上传文件
export ALIYUNPAN_CONFIG_DIR=/home/user/.config/aliyunpan
/usr/local/bin/aliyunpan sync start -ldir ${BACKUP_DIR} -pdir /backup --drive resource --mode upload --policy exclusive --cycle onetime --up 1 --dp 1 --log true > /tmp/backup/aliyunpan-${time}.log

# 推送消息
UPLOAD_STATUS=$(grep '已完成' /tmp/backup/aliyunpan-${time}.log)
if [ -z "${UPLOAD_STATUS}" ]; then
    FULL_LOG=$(cat /tmp/backup/aliyunpan-${time}.log)
    /usr/local/bin/gotify push --url ${GOTIFY_URL} --token ${GOTIFY_TOKEN} --priority 10 "备份同步失败 \n${FULL_LOG}"
else
    DELETED=$(grep '多余文件' /tmp/backup/aliyunpan-${time}.log)
    UPLOADED=$(grep '上传文件' /tmp/backup/aliyunpan-${time}.log)
    if [ -z "${DELETED}" ]; then
        DELETED=没有文件删除
    fi

    if [ -z "${UPLOADED}" ]; then
        UPLOADED=没有文件上传
    fi

    /usr/local/bin/gotify push --url ${GOTIFY_URL} --token ${GOTIFY_TOKEN} --priority 4 "${DELETED} \n${UPLOADED}"
fi

# 删除临时文件
rm -rf /tmp/backup

# vim: ts=4 sts=4 sw=4 et
