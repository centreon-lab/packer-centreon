#!/bin/sh

MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_USER="centreon"
MYSQL_PASSWD="c3ntr30n"
MYSQL_ROOT_PASSWORD="change123"
CENTREON_ADMIN_NAME="Administrator"
CENTREON_ADMIN_EMAIL="admin@admin.co"
CENTREON_ADMIN_PASSWD="change123"

InstallDbCentreon() {
    

    CENTREON_HOST="http://localhost"
    COOKIE_FILE="/tmp/install.cookie"
    CURL_CMD="curl -q -b ${COOKIE_FILE}"

    curl -q -c ${COOKIE_FILE} ${CENTREON_HOST}/centreon/install/install.php
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=stepContent"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step3.php" \
        --data "install_dir_engine=%2Fusr%2Fshare%2Fcentreon-engine&centreon_engine_stats_binary=%2Fusr%2Fsbin%2Fcentenginestats&monitoring_var_lib=%2Fvar%2Flib%2Fcentreon-engine&centreon_engine_connectors=%2Fusr%2Flib64%2Fcentreon-connector&centreon_engine_lib=%2Fusr%2Flib%2Fcentreon-engine&centreonplugins=%2Fusr%2Flib%2Fcentreon%2Fplugins%2F"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step4.php" \
        --data "centreonbroker_etc=%2Fetc%2Fcentreon-broker&centreonbroker_cbmod=%2Fusr%2Flib64%2Fnagios%2Fcbmod.so&centreonbroker_log=%2Fvar%2Flog%2Fcentreon-broker&centreonbroker_varlib=%2Fvar%2Flib%2Fcentreon-broker&centreonbroker_lib=%2Fusr%2Fshare%2Fcentreon%2Flib%2Fcentreon-broker"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step5.php" \
        --data "admin_password=${CENTREON_ADMIN_PASSWD}&confirm_password=${CENTREON_ADMIN_PASSWD}&firstname=${CENTREON_ADMIN_NAME}&lastname=${CENTREON_ADMIN_NAME}&email=${CENTREON_ADMIN_EMAIL}"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step6.php" \
        --data "address=${MYSQL_HOST}&port=${MYSQL_PORT}&root_password=${MYSQL_ROOT_PASSWORD}&db_configuration=centreon&db_storage=centreon_storage&db_user=${MYSQL_USER}&db_password=${MYSQL_PASSWD}&db_password_confirm=${MYSQL_PASSWD}"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/configFileSetup.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/installConfigurationDb.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/installStorageDb.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/createDbUser.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/insertBaseConf.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/partitionTables.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step8.php" \
        --data "modules%5B%5D=centreon-license-manager&modules%5B%5D=centreon-pp-manager&modules%5B%5D=centreon-autodiscovery-server"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step9.php" \
        --data "send_statistics=1"
}

installModules() {
    # After Centreon configuration, install modules
    if [ ! "$(rpm -aq | grep centreon-map-release)" ]; then
        MYSQL_HOST_CLIENT=$( \
            echo "SELECT host FROM information_schema.processlist WHERE ID=connection_id();" \
            | mysql -u root --password="${MYSQL_ROOT_PASSWORD}" -h ${MYSQL_HOST} \
            | sed 1d | cut -f1 -d":" \
        )
        echo "CREATE USER 'centreon_map'@'${MYSQL_HOST_CLIENT}' IDENTIFIED BY '${MYSQL_PASSWD}';" \
            | mysql -u root --password="${MYSQL_ROOT_PASSWORD}" -h ${MYSQL_HOST}
        echo "GRANT SELECT ON centreon_storage.* TO 'centreon_map'@'${MYSQL_HOST_CLIENT}';" \
            | mysql -u root --password="${MYSQL_ROOT_PASSWORD}" -h ${MYSQL_HOST}
        echo "GRANT SELECT, INSERT ON centreon.* TO 'centreon_map'@'${MYSQL_HOST_CLIENT}';" \
            | mysql -u root --password="${MYSQL_ROOT_PASSWORD}" -h ${MYSQL_HOST}
    
        yum install -y http://yum.centreon.com/centreon-map/bfcfef6922ae08bd2b641324188d8a5f/19.04/el7/stable/noarch/RPMS/centreon-map-release-19.04-1.el7.centos.noarch.rpm \
            && yum-config-manager -y -q --disable centreon-map-stable \
            && yum-config-manager -y -q --enable centreon-map-canary-noarch \
            && yum install -y centreon-map-server expect
        cd /etc/centreon-studio
        find /etc/centreon-studio -type f -name \*.sh | xargs chmod -v +x
        export PATH="$PATH:/etc/centreon-studio"
        sed -i \
            -e "s/##CENTREON_ADMIN_PASSWORD##/${CENTREON_ADMIN_PASSWD}/g" \
            -e "s/##CENTREON_HOST_DATABASE##/${MYSQL_HOST}/g" \
            -e "s/##CENTREON_USER_DB_PASSWORD##/${MYSQL_PASSWD}/g" \
            -e "s/##MYSQL_ROOT_PASSWORD##/${MYSQL_ROOT_PASSWORD}/g" \
            /tmp/configure-map.exp
        #/tmp/./configure-map.exp
    fi
    if [ ! "$(rpm -aq | grep centreon-bam-release)" ]; then
        yum install -y http://yum.centreon.com/centreon-bam/d4e1d7d3e888f596674453d1f20ff6d3/19.04/el7/stable/noarch/RPMS/centreon-bam-release-19.04-1.el7.centos.noarch.rpm \
        && yum-config-manager -y -q --disable centreon-bam-stable \
        && yum-config-manager -y -q --enable centreon-bam-canary-noarch \
        && yum install -y centreon-bam-server
    fi
    if [ ! "$(rpm -aq | grep centreon-mbi-release)" ]; then
        yum install -y http://yum.centreon.com/centreon-mbi/5e0524c1c4773a938c44139ea9d8b4d7/19.04/el7/stable/noarch/RPMS/centreon-mbi-release-19.04-1.el7.centos.noarch.rpm \
        && yum-config-manager -y -q --disable centreon-mbi-stable \
        && yum-config-manager -y -q --enable centreon-mbi-canary-noarch \
        && yum install -y centreon-bi-server
    fi

    CENTREON_HOST="http://localhost"
    CURL_CMD="curl -q -o /dev/null"
    API_TOKEN=$(curl -q -d "username=admin&password=${CENTREON_ADMIN_PASSWD}" \
        "${CENTREON_HOST}/centreon/api/index.php?action=authenticate" \
        | cut -f2 -d":" | sed -e "s/\"//g" -e "s/}//"
    )

    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=centreon-bam-server&type=module"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=centreon-bi-server&type=module"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=bam-ba-listing&type=widget"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=mbi-ba-mtbf-mtrs&type=widget"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=mbi-ba-availability-graph-day&type=widget"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=mbi-ba-availability-gauge&type=widget"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=mbi-ba-availability-graph-month&type=widget"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=mbi-bv-availability-graph-month&type=widget"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=mbi-hgs-hc-by-host-mtbf-mtrs&type=widget"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=mbi-hg-availability-by-host-graph-day&type=widget"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=mbi-hg-availability-by-hc-graph-month&type=widget"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=mbi-hgs-availability-by-hg-graph-month&type=widget"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=mbi-hgs-performances-Top-X&type=widget"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=mbi-hgs-hcs-scs-metric-performance-day&type=widget"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=mbi-metric-capacity-planning&type=widget"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=mbi-metric-capacity-planning&type=widget"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=mbi-hgs-hc-by-service-mtbf-mtrs&type=widget"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=mbi-storage-list-near-saturation&type=widget"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=mbi-storage-list-near-saturation&type=widget"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=mbi-hgs-hc-by-service-mtbf-mtrs&type=widget"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=mbi-storage-list-near-saturation&type=widget"
    ${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: ${API_TOKEN}"\
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=mbi-typical-performance-day&type=widget"

    echo "Kill Apache and PHP-FPM ..."
    kill $PID_HTTPD
    kill $PID_PHPFPM
}


yum install -y centos-release-scl wget curl

cat <<EOF > /etc/yum.repos.d/centreon.repo
[centreon-stable-noarch]
name=Centreon open source software repository.
baseurl=http://yum.centreon.com/standard/19.10/el7/stable/noarch/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CES
[centreon-stable]
name=Centreon open source software repository.
baseurl=http://yum.centreon.com/standard/19.10/el7/stable/\$basearch/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CES

[centreon-testing-noarch]
name=Centreon open source software repository. (UNSUPPORTED)
baseurl=http://yum.centreon.com/standard/19.10/el7/testing/noarch/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CES
[centreon-testing]
name=Centreon open source software repository. (UNSUPPORTED)
baseurl=http://yum.centreon.com/standard/19.10/el7/testing/\$basearch/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CES
[centreon-unstable-noarch]
name=Centreon open source software repository. (UNSUPPORTED)
baseurl=http://yum.centreon.com/standard/19.10/el7/unstable/noarch/
enabled=0
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CES
[centreon-unstable]
name=Centreon open source software repository. (UNSUPPORTED)
baseurl=http://yum.centreon.com/standard/19.10/el7/unstable/\$basearch/
enabled=0
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CES
[centreon-canary-noarch]
name=Centreon open source software repository. (UNSUPPORTED)
baseurl=http://yum.centreon.com/standard/19.10/el7/canary/noarch/
enabled=0
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CES
[centreon-canary]
name=Centreon open source software repository. (UNSUPPORTED)
baseurl=http://yum.centreon.com/standard/19.10/el7/canary/\$basearch/
enabled=0
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CES
EOF

yum install -y centreon

echo "date.timezone = Europe/Paris" > /etc/opt/rh/rh-php72/php.d/php-timezone.ini
systemctl restart mysql
mysqladmin -u root password $MYSQL_ROOT_PASSWORD # Set password to root mysql
systemctl restart rh-php72-php-fpm
systemctl restart httpd24-httpd
sleep 5 # waiting start httpd process
InstallDbCentreon # Configure database
su - centreon -c "/opt/rh/rh-php72/root/bin/php /usr/share/centreon/cron/centreon-partitioning.php"
systemctl restart cbd

# Set firstboot script
mv /tmp/scripts/firstboot.sh /root/firstboot.sh
chmod +x /root/firstboot.sh
cat <<EOF > /etc/systemd/system/firstboot.service 
[Unit]
Description=Auto-execute post install scripts
After=network.target
 
[Service]
ExecStart=/root/firstboot.sh
 
[Install]
WantedBy=multi-user.target
EOF

systemctl enable firstboot

# Enable all others services
systemctl enable mysql
systemctl enable httpd24-httpd
systemctl enable snmpd
systemctl enable snmptrapd
systemctl enable rh-php71-php-fpm
systemctl enable centcore
systemctl enable centreontrapd
systemctl enable cbd
systemctl enable centengine
systemctl enable centreon
