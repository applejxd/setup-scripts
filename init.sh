#!/bin/sh

sudo apt update

mkdir -p ~/src
cd ~/src

if !(type "jq" >/dev/null 2>&1); then
    # for parse json
    sudo apt install -y jq
fi

response=$(curl https://api.github.com/repos/SoftEtherVPN/SoftEtherVPN_Stable/releases/latest)
download_url=$(echo $response | jq ".assets[38].browser_download_url" | sed 's/"//g')
file_name=$(echo $response | jq ".assets[38].name" | sed 's/"//g')
wget $download_url
tar zxvf $file_name

if !(type "make" >/dev/null 2>&1); then
    sudo apt install -y build-essential
fi

cd vpnserver
yes 1 | make
find . -type f -print | xargs chmod 600
find . -type d -print | xargs chmod 700
chmod u+x .install.sh vpncmd vpnserver
cd ~/src
sudo cp -rp vpnserver /usr/local/
sudo chown -R root:root /usr/local/vpnserver/

sudo tee /etc/systemd/system/vpnserver.service <<EOF >/dev/null
[Unit]
Description=SoftEther VPN Server
After=network.target auditd.service
ConditionPathExists=!/usr/local/vpnserver/do_not_run

[Service]
Type=forking
EnvironmentFile=-/usr/local/vpnserver
ExecStart=/usr/local/vpnserver/vpnserver start
ExecStop=/usr/local/vpnserver/vpnserver stop
KillMode=process
Restart=on-failure

# Hardening
PrivateTmp=yes
ProtectHome=yes
ProtectSystem=full
ReadOnlyDirectories=/
ReadWriteDirectories=-/usr/local/vpnserver
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_BROADCAST CAP_NET_RAW CAP_SYS_NICE CAP_SYS_ADMIN CAP_SETUID

[Install]
WantedBy=multi-user.target
EOF
