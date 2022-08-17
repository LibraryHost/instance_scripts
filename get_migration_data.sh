#!/bin/bash

host="${4}"

database=$2
dir="${1}_migrate"
target=$3

echo "RUNNING"
echo $host
echo "================="

ssh $host "sudo mkdir /root/${dir}"
#ssh $host "sudo mysqldump --defaults-file=/root/.my.cnf ${database} > /root/${dir}/${database}_migration.sql"
ssh $host "sudo /bin/sh -c 'mysqldump --defaults-file=/root/.my.cnf ${database} > /root/${dir}/${database}_migration.sql'"
echo "================="
ssh $host "sudo cp /var/www/${1}/config/config.rb /root/${dir}"
echo "PASSWORD"
echo "================="
ssh $host "sudo grep 'user=${database}&password' /var/www/${1}/config/config.rb"
echo "================="

echo "CONFIG"
echo "================="
ssh $host "sudo grep '^[^#]' /var/www/${1}/config/config.rb | grep -v ':default_admin_password' | grep -v ':db_url' | grep -v 'frontend_proxy_url' | grep -v 'frontend_prefix' | grep -v 'public_proxy_url' | grep -v 'indexer_thread_count' | grep -v 'backend_log_level' | grep -v 'enable_docs' | grep -v 'pui_request_email_' | grep -v 'pui_email_'"  
echo "================="

echo "EMAIL"
echo "================="
ssh $host "sudo grep 'pui_request_email_fallback_to_address' /var/www/${1}/config/config.rb"
echo "================="
ssh $host "sudo cp /etc/apache2/sites-available/${1}.conf /root/${dir}"

echo "DOMAINS"
echo "================="
ssh $host "sudo grep 'ServerName' /etc/apache2/sites-available/${1}.conf"
echo "================="

ssh $host "sudo apt install -y zip"
#ssh $host "sudo cp -r /var/www/${1}/plugins /root/${dir}"
ssh $host "sudo /bin/sh -c 'cd /var/www/${1} && zip -r /root/${dir}/plugins.zip plugins'"
ssh $host "sudo /bin/sh -c 'cd /root && zip -r ${dir}.zip ${dir}'"
ssh $host "sudo cp /root/${dir}.zip /home/manny"
scp -r $host:$dir.zip .
scp -r $dir.zip root@$target:/root/to_migrate
