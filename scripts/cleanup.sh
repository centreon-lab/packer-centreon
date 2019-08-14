#!/bin/sh

yum -y clean all

# Clean network configuration
ip -o link show | awk -F': ' '{print $2}' | grep -v lo | while read INTERFACE; do
    if [ -e /etc/sysconfig/network-scripts/ifcfg-${INTERFACE} ]; then
        sed -i '/HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-${INTERFACE}
        sed -i "/^UUID/d" /etc/sysconfig/network-scripts/ifcfg-${INTERFACE}
        sed -i "/^UUID/d" /etc/sysconfig/network-scripts/ifcfg-${INTERFACE}
    fi
    rm -f /var/lib/dhclient/dhclient-${INTERFACE}.leases
done
rm -f /etc/ssh/ssh_host_*
rm -f /etc/udev/rules.d/70-persistent-net.rules

rm -rf /tmp/*