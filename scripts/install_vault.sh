#!/bin/bash -v

apt-get update -y

apt-get install unzip wget -y

wget https://releases.hashicorp.com/vault/0.10.3/vault_0.10.3_linux_amd64.zip
unzip -j vault_*_linux_amd64.zip -d /usr/local/bin

useradd -r -g daemon -d /usr/local/vault -m -s /sbin/nologin -c "Vault user" vault

mkdir /etc/vault /etc/ssl/vault /mnt/vault
chown vault.root /etc/vault /etc/ssl/vault /mnt/vault
chmod 750 /etc/vault /etc/ssl/vault
chmod 700 /usr/local/vault

cat <<EOF | sudo tee /etc/vault/config.hcl
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}
backend "file" {
  path = "/mnt/vault/data"
}
disable_mlock = true
ui = true
EOF

cat <<EOF | sudo tee /etc/systemd/system/vault.service
[Unit]
Description=Vault service
After=network-online.target

[Service]
User=vault
Group=daemon
PrivateDevices=yes
PrivateTmp=yes
ProtectSystem=full
ProtectHome=read-only
SecureBits=keep-caps
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/vault server -config=/etc/vault/config.hcl
KillSignal=SIGINT
TimeoutStopSec=30s
Restart=on-failure
StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 0644 /etc/systemd/system/vault.service

service vault start
