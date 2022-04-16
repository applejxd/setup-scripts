#!/bin/sh

if [ $# -eq 0 ]; then
    # Save Password
    read -sp "Password: " password
else
    password=$1
fi

echo "$password" | sudo -S -E apt-get update

################
# Dependencies #
################

# for download
if !(type "jq" >/dev/null 2>&1); then
    # for parse json
    echo "$password" | sudo -S -E apt-get install -y jq
fi

if !(type "make" >/dev/null 2>&1); then
    sudo apt install -y build-essential
fi

###########
# Install #
###########

# Get download URL (arm_eabi-32bit)
response=$(curl https://api.github.com/repos/SoftEtherVPN/SoftEtherVPN_Stable/releases/latest)
download_url=$(echo $response | jq ".assets[35].browser_download_url" | sed 's/"//g')
file_name=$(echo $response | jq ".assets[35].name" | sed 's/"//g')

# Download
mkdir -p ~/src
cd ~/src
wget $download_url
tar zxvf $file_name

# Build
cd vpnserver
yes 1 | make
find . -type f -print | xargs chmod 600
find . -type d -print | xargs chmod 700
chmod u+x .install.sh vpncmd vpnserver

# Install
cd ~/src
sudo cp -rp vpnserver /usr/local/
sudo chown -R root:root /usr/local/vpnserver/

###########
# systemd #
###########

# cf. https://dsp74118.blogspot.com/2016/02/vpssoftether-vpnlan.html

echo "$password" | sudo -S -E tee /etc/systemd/system/vpnserver.service <<EOF >/dev/null
[Unit]
Description=SoftEther VPN Server
After=network.target
 
[Service]
Type=forking
ExecStart=/usr/local/vpnserver/vpnserver start
ExecStop=/usr/local/vpnserver/vpnserver stop
 
[Install]
WantedBy=multi-user.target
EOF

###########
# Service #
###########

echo "$password" | sudo -S -E systemctl daemon-reload
echo "$password" | sudo -S -E systemctl enable vpnserver
echo "$password" | sudo -S -E systemctl start vpnserver
