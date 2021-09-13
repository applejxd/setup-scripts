#!/bin/sh

read -sp "Input IP address for virtual hub: " hub_ip
read -sp "Input IP address for router (gateway): " router_ip

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
After=network.target
 
[Service]
Type=forking
ExecStart=/opt/vpnserver.sh start
ExecStop=/opt/vpnserver.sh stop
ExecReload=/opt/vpnserver.sh restart
 
[Install]
WantedBy=multi-user.target
EOF

script_contents=$(curl -L https://raw.githubusercontent.com/applejxd/softether-setup/main/vpnserver.sh | sed -e "s/HUB_IP/$hub_ip/g" -e "s/ROUTER_IP/$router_ip/g")
echo $script_contents | sudo tee /opt/vpnserver.sh

sudo systemctl daemon-reload
sudo systemctl enable vpnserver
sudo systemctl start vpnserver
