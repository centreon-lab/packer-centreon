#!/bin/sh

if [[ $EUID -eq 0 ]]; then
    systemctl restart mysql
    systemctl restart rh-php72-php-fpm
    systemctl restart httpd24-httpd
    sleep 5
    /opt/rh/rh-php72/root/bin/php /tmp/scripts/generateUUID.php > /var/log/centreon/generateUUID.log 2>&1
    /opt/rh/rh-php72/root/bin/php /tmp/scripts/generateAppKey.php > /var/log/centreon/generateAppKey.php 2>&1
    MINUTES=$(($RANDOM % 59 + 1 | bc))
    HOURS=$(($RANDOM % 23 + 1 | bc))
    sed -r -i "s|[0-9]+ [0-9]+ (.* /usr/share/centreon/cron/centreon-send-stats.php .*)|$MINUTES $HOURS \1|g" /etc/cron.d/centreon
    /usr/bin/systemctl restart centcore
    /usr/bin/systemctl restart centreontrapd
    /usr/bin/systemctl restart cbd
fi

systemctl disable firstboot
rm -rf /root/firstboot.sh
exit 0