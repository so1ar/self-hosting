#!/bin/bash

# 备份文件夹，按需修改
BACKUP_FOLDER=/home/user/backup
# 容器文件夹，按需修改
CONTAINER_FOLDER=/home/user/containers/freshrss

# 进入 FreshRSS 文件夹
cd ${BACKUP_FOLDER}/freshrss

# 显示备份时间
rm -rf *.txt
time=$(date +%Y%m%d%H%M)
echo ${time} > ${time}.txt

# 停止容器
docker stop freshrss

# 旧的备份文件
mv FreshRSS-backup.tgz.gpg FreshRSS-backup-old.tgz.gpg

# 开始备份 FreshRSS
tar -czf FreshRSS-backup.tgz -C ${CONTAINER_FOLDER} .

# 加密文件，需要改成自己的公钥
gpg --recipient so1ar --encrypt FreshRSS-backup.tgz

# 删除未加密文件
rm -rf FreshRSS-backup.tgz

# 上传文件到坚果云
rclone sync ${BACKUP_FOLDER} nutstore:backup

# 重新启动容器
docker start freshrss
