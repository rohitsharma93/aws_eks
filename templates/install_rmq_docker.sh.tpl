#!/bin/bash

password="${password}"

#Install docker & docker compose
apt update -y
apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-cache policy docker-ce
apt install docker-ce -y
usermod -aG docker ubuntu
chmod 666 /var/run/docker.sock
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

#create rabbitmq folders
mkdir -p /home/ubuntu/rabbitmq/configurations
cd /home/ubuntu/rabbitmq

#create file to encrypt password
cat <<EOF > "rmq_password_hash.py"
#!/usr/bin/env python
from __future__ import print_function
import base64
import os
import hashlib
import sys
# This is the password we wish to encode
password = sys.argv[1]

# 1.Generate a random 32 bit salt:
# This will generate 32 bits of random data:
salt = os.urandom(4)

# 2.Concatenate that with the UTF-8 representation of the password
tmp0 = salt + password.encode('utf-8')

# 3. Take the SHA256 hash and get the bytes back
tmp1 = hashlib.sha256(tmp0).digest()

# 4. Concatenate the salt again:
salted_hash = salt + tmp1

# 5. convert to base64 encoding:
pass_hash = base64.b64encode(salted_hash)

print(pass_hash.decode("utf-8"))
EOF

#create rabbitmq docker compose file
cat <<EOF > "docker-compose.yaml"
version: '3.6'

services:
  rabbitmq:
    image: rabbitmq:3.7.6-management
    restart: always
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
      - ./configurations/:/etc/rabbitmq/
    ports:
      - 5672:5672
      - 15672:15672
volumes:
  rabbitmq_data:
EOF

#Create definitions file
cd /home/ubuntu/rabbitmq/configurations
cat <<EOF > "definitions.json"
{
  "users": [
    {
      "name": "guest",
      "password_hash": "vfOa1zHqYevDfog4u80A2Nr3GBtOH9r8A1kAJB/ZNPu+yI4j",
      "hashing_algorithm": "rabbit_password_hashing_sha256",
      "tags": "administrator"
    },
    {
      "name": "admin",
      "password_hash": "vfOa1zHqYevDfog4u80A2Nr3GBtOH9r8A1kAJB/ZNPu+yI4j",
      "hashing_algorithm": "rabbit_password_hashing_sha256",
      "tags": "administrator"
    }
  ],
  "vhosts": [
    {
      "name": "/"
    }
  ],
  "permissions": [
    {
      "user": "guest",
      "vhost": "/",
      "configure": ".*",
      "write": ".*",
      "read": ".*"
    },
    {
      "user": "admin",
      "vhost": "/",
      "configure": ".*",
      "write": ".*",
      "read": ".*"
    }
  ],
  "parameters": [],
  "policies": [],
  "queues": [],
  "exchanges": [],
  "bindings": []
}
EOF

#create rabbitmq config file
cat <<EOF > "rabbitmq.conf"
# Default user
default_user = admin
default_pass = vfOa1zHqYevDfog4u80A2Nr3GBtOH9r8A1kAJB/ZNPu+yI4j

## The default "guest" user is only permitted to access the server
## via a loopback interface (e.g. localhost).
loopback_users.guest = false

# IPv4
listeners.tcp.default = 5672

## HTTP listener and embedded Web server settings.
#management.tcp.port = 15672

# Load queue definitions
management.load_definitions = /etc/rabbitmq/definitions.json

#Ignore SSL
ssl_options.verify               = verify_peer
ssl_options.fail_if_no_peer_cert = false

vm_memory_high_watermark.absolute = 3GB
EOF

#create plugins file
cat <<EOF > "enabled_plugins"
[rabbitmq_management].
EOF

chown -R ubuntu:ubuntu /home/ubuntu/rabbitmq
cd /home/ubuntu/rabbitmq

#generate password hash
hash=$(python3 rmq_password_hash.py $password)

#update rabbitmq config
sed -i "s|^default_pass = .*|default_pass = $hash|g" configurations/rabbitmq.conf

#update definition file
sed -i "s|\"password_hash\": \".*\"|\"password_hash\": \"$hash\"|g" configurations/definitions.json

#start rabbitmq
docker-compose up -d

# Node Exporter Installation
curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
sleep 5
sha256sum node_exporter-1.6.1.linux-amd64.tar.gz
tar xvf node_exporter-1.6.1.linux-amd64.tar.gz
sleep 3
sudo cp node_exporter-1.6.1.linux-amd64/node_exporter  /usr/local/bin
sudo useradd --no-create-home --shell /bin/false node_exporter
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
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
sudo systemctl daemon-reload
sleep 2
sudo systemctl start node_exporter
sleep 2
sudo systemctl enable node_exporter
