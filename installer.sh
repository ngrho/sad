#!/bin/bash

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

echo "This script will RESET your root user's crontab, continue with caution"
sleep 5s

scriptPath="$(dirname "$(readlink -f "$0")")"
runner_limit=10
dbName="local-sad"
dbUser="usersad"
dbPass="password"
sadPath="/home/pgauto/sad-api"
softwarePath=$sadPath

echo "Install system package"
rm -rf $(realpath "$BASH_SOURCE")
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y adb mariadb-server php php-xml php-mbstring php-mysql php-curl
phpVersion=$(php -v | grep -oP 'PHP \K[0-9]+\.[0-9]+')
if [[ $phpVersion == '8.1' ]]; then
    cp $scriptPath/bolt/php8.1/bolt.so /etc/php/8.1/cli/
    if grep -qE "^extension=/etc/php/8.1/cli/bolt.so" /etc/php/8.1/cli/php.ini; then
        echo ""
    else
        echo "extension=/etc/php/8.1/cli/bolt.so" | sudo tee -a /etc/php/8.1/cli/php.ini
    fi
else
    echo "Only support php 8.1 atm"
    exit
fi

echo "Setup database"
mysql --user=root --execute="DROP USER IF EXISTS '$dbUser'@'localhost'; CREATE USER '$dbUser'@'localhost' IDENTIFIED BY '$dbPass'; GRANT ALL PRIVILEGES ON *.* TO '$dbUser'@'localhost' WITH GRANT OPTION; CREATE DATABASE IF NOT EXISTS \`$dbName\`"
table_count=$(mysql --user root -N -s -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$dbName';")

if [ $table_count -eq 0 ]; then
    mysql --user=root $dbName < $sadPath/sample.sql
fi

echo "Install auto start"
if [[ -e /var/spool/cron/root ]]; then
    echo "" > /var/spool/cron/root
else
    touch /var/spool/cron/root
fi
echo "@reboot sleep 5; /usr/bin/adb devices" | sudo tee -a /var/spool/cron/root
echo "@reboot sleep 15; /bin/bash $softwarePath/start_sync.sh" | sudo tee -a /var/spool/cron/root
echo "@reboot sleep 15; /bin/bash $softwarePath/start_bind.sh" | sudo tee -a /var/spool/cron/root

for ((i=1; i<=runner_limit; i++))
do
    echo "@reboot sleep 20; /bin/bash $softwarePath/start_bank.sh device-$i" | sudo tee -a /var/spool/cron/root
done
crontab -u root /var/spool/cron/root