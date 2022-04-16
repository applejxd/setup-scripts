# SoftEtherVPN

## Requirements

- OS: Ubuntu 18.04 or higher
- Configurations: Need to define two IP addresses
    - For virtual Hub (LAN IP of AWS server)
    - For router (gateway)

## How to Install 

Establish SoftEther VPN Server on VPS server

```shell
# for aws (for VPN server)
bash -c "$(curl -L https://raw.githubusercontent.com/applejxd/setup-scripts/main/softether-vpn/aws_init.sh)"
# for raspi (for VPN bridge)
bash -c "$(curl -L https://raw.githubusercontent.com/applejxd/setup-scripts/main/softether-vpn/raspi_init.sh)"
```
