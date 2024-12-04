#!/bin/bash

# this script copies an instance to another server, ready to migrate in
# it:
# does a database dump and scps to the new server
# copies over instance folder in /var/www
# copies over apache conf
# outputs aspace version

db_name=$1
folder_name=$2
apache_name=$3
target_server=$4

work_dir=/root/to_move

if [ ! -d "/var/www/$folder_name" ]; then
  echo "/var/www/$folder_name does not exist."
  exit 1
fi

if [ ! -f "/etc/apache2/sites-available/$apache_name.conf" ]; then
  echo "/etc/apache2/sites-available/$apache_name.conf does not exist."
  exit 1
fi

echo "DB_NAME: ${db_name}"
echo "FOLDER_NAME: ${folder_name}"
echo "APACHE_NAME: ${apache_name}"
echo "TARGET_SERVER: ${target_server}"

read -p "Does this look OK? Press 'y' to confirm: " -r REPLY
if [ "$REPLY" = "y" ];
then
  echo "Proceeding..."
else
  echo "Aborting."
  exit
fi

mkdir $work_dir/$folder_name
mysqldump --defaults-file=/root/.my.cnf $db_name > /root/to_move/$folder_name/$db_name.sql
cp -r /var/www/$folder_name /root/to_move/$folder_name
cp /etc/apache2/sites-available/$apache_name.conf /root/to_move/$folder_name/$apache_name.conf

pushd /root/to_move
zip -r $folder_name.zip $folder_name
popd

scp /root/to_move/$folder_name.zip root@$target_server:/root/moved






