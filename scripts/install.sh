#!/bin/bash -e

CWD=$(cd $(dirname $0); pwd)

##############################################################
# Basic Configuration
##############################################################
echo "Configuring system ..."

## encoding
cat >> /etc/environment << EOF
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
EOF

## timezone
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime

## disable firewall and iptables
systemctl disable firewalld.service

## disable kdump
systemctl disable kdump.service

## disable NetworkManager
systemctl disable NetworkManager.service
systemctl stop NetworkManager.service

## remove unused ifcfg
rm -f /etc/sysconfig/network-scripts/ifcfg-en*

## make 'eth0' the predictable network device
rm -f /etc/udev/rules.d/70*
ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules || true


##############################################################
# Running ovfenv-installer for next reboot
##############################################################
yum install -y https://github.com/subchen/ovfenv-installer/releases/download/v1.0.2/ovfenv-installer-1.0.2-17.x86_64.rpm

cat >> /etc/rc.d/rc.local << EOF
ovfenv-installer --run-once --log-file=/var/log/ovfenv-installer.log
EOF

chmod +x /etc/rc.d/rc.local
