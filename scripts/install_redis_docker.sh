#!/bin/bash

# Installing Docker

apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
apt update -y
apt-cache policy docker-ce
apt install  docker.io -y
echo "docker successfully installed"
curl -SL https://github.com/docker/compose/releases/download/v2.3.4/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
usermod -a -G docker ubuntu

# Creating redis directory
cd /home/ubuntu/
mkdir redis
cd redis/

# Created Docker Compose YAML file
cat <<EOF > "docker-compose.yml"
version: '2'

services:
  redis:
    image: 'redis:7.0'
    restart: always 
    container_name: Redis-Server
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
    ports:
      - "6379:6379"
    volumes:
      - ./config/redis.conf:/usr/local/etc/redis/redis.conf
      - ./cache:/data
    entrypoint: redis-server /usr/local/etc/redis/redis.conf
    deploy:
      resources:
        limits:
          memory: 2048M
        reservations:
          memory: 1024M
EOF

# Run Docker Compose
docker-compose up -d

# Node Exporter Installation
curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
sleep 5
sha256sum node_exporter-1.6.1.linux-amd64.tar.gz
tar xvf node_exporter-1.6.1.linux-amd64.tar.gz
sleep 3
cp node_exporter-1.6.1.linux-amd64/node_exporter  /usr/local/bin
useradd --no-create-home --shell /bin/false node_exporter
chown node_exporter:node_exporter /usr/local/bin/node_exporter
rm -rf node_exporter-1.6.1.linux-amd64 node_exporter-1.6.1.linux-amd64.tar.gz
cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --collector.systemd

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
sleep 2
systemctl start node_exporter
sleep 2
systemctl enable node_exporter
