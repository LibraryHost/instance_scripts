#!/bin/bash

# this script loads in instance data from an instance copied over with the move_instance.sh script
# the zip file copied over has a directory, INSTANCE_NAME, with the following contents:
# INSTANCE_NAME/ -> /var/www/folder
# INSTANCE_NAME.conf -> apache2 config copied from other folder
# INSTANCE_NAME.sql -> instance database dump
#
# INSTANCE_NAME may be different between the folder, conf and sql in some cases.
#
# 1. unzip file
# 2. create database and load dump
# 3. update apache conf with correct instance number, move to apache conf dir and enable
# 4. move /var/www folder in place, update config.rb with correct instance number

name=$1
apache_name=$2
db_name=$3
db_password=$4
old_instance_number=$5
instance_number=$6
ram=$7
aspace_version=$8
solr_core_name=$9
work_dir=/root/moved

echo "NAME: ${name}"
echo "APACHE_NAME: ${apache_name}"
echo "DB_NAME: ${db_name}"
echo "DB_PASSWORD: ${db_password}"
echo "OLD_INSTANCE_NUMBER: ${old_instance_number}"
echo "INSTANCE_NUMBER: ${instance_number}"
echo "RAM: ${ram}"
echo "ASPACE_VERSION: ${aspace_version}"
echo "SOLR_CORE_NAME: ${solr_core_name}"

read -p "Does this look OK? Press 'y' to confirm: " -r REPLY
if [ "$REPLY" = "y" ];
then
  echo "Proceeding..."
else
  echo "Aborting."
  exit
fi

#Unzip
unzip ${work_dir}/${name}.zip -d ${work_dir}

# create DB, users, import file
echo "CREATE DATABASE ${db_name};" > ${work_dir}/${db_name}_create.sql
echo "CREATE USER '${db_name}'@'localhost' IDENTIFIED BY '${db_password}';" >> ${work_dir}/${db_name}_create.sql
echo "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_name}'@'localhost';" >> ${work_dir}/${db_name}_create.sql
echo "FLUSH PRIVILEGES;" >> ${work_dir}/${db_name}_create.sql
mysql --defaults-file=/root/.my.cnf < ${work_dir}/${db_name}_create.sql
mysql --defaults-file=/root/.my.cnf ${db_name} < ${work_dir}/${name}/${db_name}.sql
echo "DONE WITH DB!"

# move over /var/www folder, update port numbers in config.rb
mv $work_dir/$name/$name /var/www
sed -i "s/localhost:$old_instance_number/localhost:$instance_number/g" /var/www/$name/config/config.rb

# update apache conf with correct instance number
sed -i "s/localhost:$old_instance_number/localhost:$instance_number/g" $work_dir/$name/$apache_name.conf
cp $work_dir/$name/$apache_name.conf /etc/apache2/sites-available/$apache_name.conf
a2ensite $apache_name
service apache2 restart
echo "DONE WITH APACHE!"

# create solr core
if [ -z $solr_core_name ];
then
  echo "Solr core name not specified, assuming version < 3.2 and not creating core."
else
  #SOLR for 3.2
  if [[ $aspace_version = "3.2.0"  ]]
  then
    sudo -H -u solr bash -c "/opt/solr/bin/solr create -c ${solr_core_name} -d archivesspace"
    echo "DONE WITH SOLR!"
  fi

  if [[ $aspace_version = "3.3.1"  ]]
  then
    sudo -H -u solr bash -c "/opt/solr/bin/solr create -c ${solr_core_name} -d archivesspace331"
    echo "DONE WITH SOLR!"
  fi

  if [[ $aspace_version = "3.4.0"  ]]
  then
    sudo -H -u solr bash -c "/opt/solr/bin/solr create -c ${solr_core_name} -d archivesspace340"
    echo "DONE WITH SOLR!"
  fi

  if [[ $aspace_version = "3.4.1"  ]]
  then
    sudo -H -u solr bash -c "/opt/solr/bin/solr create -c ${solr_core_name} -d archivesspace340"
    echo "DONE WITH SOLR!"
  fi

  if [[ $aspace_version = "3.5.0"  ]]
  then
    sudo -H -u solr bash -c "/opt/solr/bin/solr create -c ${solr_core_name} -d archivesspace350"
    echo "DONE WITH SOLR!"
  fi

  if [[ $aspace_version = "3.5.1"  ]]
  then
    sudo -H -u solr bash -c "/opt/solr/bin/solr create -c ${solr_core_name} -d archivesspace351"
    echo "DONE WITH SOLR!"
  fi
fi


# create docker container

docker run --name ${name}-${ram} -d -it --net=host -e ARCHIVESSPACE_DB_TYPE=mysql -e ARCHIVESSPACE_DB_HOST_TYPE=external -e ASPACE_JAVA_XMX=-Xmx${ram}m -v /var/www/${name}/config:/archivesspace/config -v /var/www/${name}/plugins:/archivesspace/plugins archivesspace/archivesspace:${aspace_version}

