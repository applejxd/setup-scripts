#!/bin/sh

if [ $# -eq 0 ]; then
    # save password
    read -sp "Password: " password
else
    password=$1
fi

echo "$password" | sudo -S apt update

mkdir -p ~/src/
cd ~/src/

if !(type "jq" >/dev/null 2>&1); then
    # for parse json
    echo "$password" | sudo -S apt install -y jq
fi

response=$(curl https://api.github.com/repos/SoftEtherVPN/SoftEtherVPN_Stable/releases/latest)
download_url=$(echo $response | jq ".assets[38].browser_download_url" | sed 's/"//g')
file_name=$(echo $response | jq ".assets[38].name" | sed 's/"//g')
wget $download_url
tar zxvf $file_name

if !(type "make" >/dev/null 2>&1); then
    echo "$password" | sudo -S apt install -y build-essential
fi

cd vpnserver
yes 1 | make
echo "$password" | sudo -S sh -c "find -name . -type f -print | xargs chmod 600"
echo "$password" | sudo -S sh -c "find -name . -type d -print | xargs chmod 700"
echo "$password" | sudo -S chmod u+x .install.sh vpncmd vpnserver
echo "$password" | sudo -S cp -rp vpnserver /usr/local/
echo "$password" | sudo -S chown -R root:root /usr/local/vpnserver/