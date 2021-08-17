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
After=network.target
 
[Service]
Type=forking
ExecStart=/opt/vpnserver.sh start
ExecStop=/opt/vpnserver.sh stop
ExecReload=/opt/vpnserver.sh restart
 
[Install]
WantedBy=multi-user.target
EOF

sudo tee /opt/vpnserver.sh <<EOF >/dev/null
#!/bin/sh
# description: SoftEther VPN Server
DAEMON=/usr/local/vpnserver/vpnserver
LOCK=/var/lock/subsys/vpnserver
test -x $DAEMON || exit 0
case "$1" in
start)
$DAEMON start
touch $LOCK
i=0
while [ $i -lt 10 ]; do
  sleep 1
  if [ `nmcli c show | grep tap_vpn | wc -l` -gt 0 ]; then
    /usr/bin/nmcli connection modify tap_vpn ipv4.method manual ipv4.addresses 192.168.0.252/24 ipv4.gateway 192.168.0.1
    /usr/bin/nmcli connection down tap_vpn
    /usr/bin/nmcli connection up tap_vpn
    logger /opt/vpnserver.sh:tap_vpn ip address set successful
    break
  fi
  i=$((i+1))
done
;;
stop)
$DAEMON stop
rm $LOCK
;;
restart)
$DAEMON stop
sleep 3
$DAEMON start
i=0
while [ $i -lt 10 ]; do
  sleep 1
  if [ `nmcli c show | grep tap_vpn | wc -l` -gt 0 ]; then
    /usr/bin/nmcli connection modify tap_vpn ipv4.method manual ipv4.addresses 192.168.0.252/24 ipv4.gateway 192.168.0.1
    /usr/bin/nmcli connection down tap_vpn
    /usr/bin/nmcli connection up tap_vpn
    logger /opt/vpnserver.sh:tap_vpn ip address set successful
    break
  fi
  i=$((i+1))
done
;;
*)
echo "Usage: $0 {start|stop|restart}"
exit 1
esac
exit 0
EOF

sudo systemctl daemon-reload
sudo systemctl enable vpnserver
sudo systemctl start vpnserver
