#!/bin/sh

if [ $# -eq 0 ]; then
    # save password
    read -sp "Password: " password
else
    password=$1
fi

echo "$password" | sudo -S apt update

if !(type "jq" >/dev/null 2>&1); then
    # for parse json
    echo "$password" | sudo -S apt install -y jq
fi

mkdir -p ~/src/vpnserver/
cd ~/src/vpnserver/

response=$(curl https://api.github.com/repos/SoftEtherVPN/SoftEtherVPN_Stable/releases/latest)
download_url=$(echo $response | jq ".assets[38].browser_download_url" | sed 's/"//g')
file_name=$(echo $response | jq ".assets[38].name" | sed 's/"//g')
wget $download_url
tar zxvf $file_name

cd vpnserver
yes 1 | make
find . -type f | chmod 600
find . -type d | chmod 700
chmod u+x .install.sh vpncmd vpnserver
sudo cp -rp vpnserver /usr/local/
sudo chown -R root:root /usr/local/vpnserver/