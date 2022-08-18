#!/bin/bash

name=$1
db_name=$2
db_password=$3
instance_number=$4
email=$5
ram=$6
version=$7

echo "NAME: ${name}"
echo "DB_NAME: ${db_name}"
echo "DB_PASSWORD: ${db_password}"
echo "INSTANCE NUMBER: ${instance_number}"
echo "EMAIL: ${email}"
echo "RAM: ${ram}"
echo "VERSION: ${version}"

# create DB, users, import file
echo "CREATE DATABASE ${db_name};" > ./${name}_migrate/${db_name}_create.sql
echo "CREATE USER '${db_name}'@'localhost' IDENTIFIED BY '${db_password}';" >> ./${name}_migrate/${db_name}_create.sql
echo "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_name}'@'localhost';" >> ./${name}_migrate/${db_name}_create.sql
echo "FLUSH PRIVILEGES;" >> ./${name}_migrate/${db_name}_create.sql
mysql --defaults-file=/root/.my.cnf < ./${name}_migrate/${db_name}_create.sql
mysql --defaults-file=/root/.my.cnf ${db_name} < ./${name}_migrate/${db_name}_migration.sql
echo "DONE WITH DB!"

#CREATE DIRECTORIES, PLUGINS
mkdir -p /var/www/${db_name}/{logs,plugins,config}
cp -r /root/instance_files/plugins32/* /var/www/${db_name}/plugins
#chmod 644 /var/www/${db_name}/plugins/local/public/assets/*

cp -r ./config.rb.template /var/www/${db_name}/config/config.rb

sed -i "s/INSTANCE/${db_name}/g" /var/www/${db_name}/config/config.rb
sed -i "s/DOMAIN/${name}/g" /var/www/${db_name}/config/config.rb
sed -i "s/PASSWORD/${db_password}/g" /var/www/${db_name}/config/config.rb
sed -i "s/XX/${instance_number}/g" /var/www/${db_name}/config/config.rb
sed -i "s/EMAIL/${email}/g" /var/www/${db_name}/config/config.rb

echo "DONE WITH ASPACE DIR!"

#APACHE CONF

cp -r ./instance.conf.template /etc/apache2/sites-available/${db_name}.conf
sed -i "s/INSTANCE/${db_name}/g" /etc/apache2/sites-available/${db_name}.conf
sed -i "s/XX/${instance_number}/g" /etc/apache2/sites-available/${db_name}.conf
sed -i "s/DOMAIN/${name}/g" /etc/apache2/sites-available/${db_name}.conf
a2ensite ${db_name}
service apache2 restart

echo "DONE WITH APACHE!"

#SOLR for 3.2
if [[ $version = "3.2.0"  ]]
then
sudo -H -u solr bash -c "/opt/solr/bin/solr create -c ${db_name} -d archivesspace"
echo "AppConfig[:solr_url] = 'http://localhost:8983/solr/${db_name}'" >> /var/www/${db_name}/config/config.rb
echo "DONE WITH SOLR!"
fi

#DOCKER CONTAINER

docker run --name ${db_name}-${ram} -d -it --net=host -e ARCHIVESSPACE_DB_TYPE=mysql -e ARCHIVESSPACE_DB_HOST_TYPE=external -e ASPACE_JAVA_XMX=-Xmx${ram}m -v /var/www/${db_name}/config:/archivesspace/config -v /var/www/${db_name}/plugins:/archivesspace/plugins archivesspace/archivesspace:${version}

