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
    /usr/bin/nmcli connection modify tap_vpn ipv4.method manual ipv4.addresses HUB_IP/24 ipv4.gateway ROUTER_IP
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
    /usr/bin/nmcli connection modify tap_vpn ipv4.method manual ipv4.addresses HUB_IP/24 ipv4.gateway ROUTER_IP
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