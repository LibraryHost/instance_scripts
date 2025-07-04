
#!/bin/bash

name=$1
db_name=$2
db_password=$3
instance_number=$4
email=$5
ram=$6
version=$7
domain=$8
work_dir=/root/created

echo "NAME: ${name}"
echo "DB_NAME: ${db_name}"
echo "DB_PASSWORD: ${db_password}"
echo "INSTANCE NUMBER: ${instance_number}"
echo "EMAIL: ${email}"
echo "RAM: ${ram}"
echo "VERSION: ${version}"
echo "DOMAIN: ${domain}"

read -p "Does this look OK? Press 'y' to confirm: " -r REPLY
if [ "$REPLY" = "y" ];
then
  echo "Proceeding..."
else
  echo "Aborting."
  exit
fi

# create DB, users, import file
echo "CREATE DATABASE ${db_name};" > ${work_dir}/${db_name}_create.sql
echo "CREATE USER '${db_name}'@'localhost' IDENTIFIED BY '${db_password}';" >> ${work_dir}/${db_name}_create.sql
echo "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_name}'@'localhost';" >> ${work_dir}/${db_name}_create.sql
echo "FLUSH PRIVILEGES;" >> ${work_dir}/${db_name}_create.sql
mysql --defaults-file=/root/.my.cnf < ${work_dir}/${db_name}_create.sql
echo "DONE WITH DB!"

#CREATE DIRECTORIES, PLUGINS
mkdir -p /var/www/${db_name}/{logs,plugins,config}
cp -r /root/instance_files/plugins32/* /var/www/${db_name}/plugins
chmod 644 /var/www/${db_name}/plugins/local/public/assets/*

cp -r ./config.rb.template /var/www/${db_name}/config/config.rb

sed -i "s/INSTANCE/${db_name}/g" /var/www/${db_name}/config/config.rb
sed -i "s/DOMAIN/${domain}/g" /var/www/${db_name}/config/config.rb
sed -i "s/PASSWORD/${db_password}/g" /var/www/${db_name}/config/config.rb
sed -i "s/XX/${instance_number}/g" /var/www/${db_name}/config/config.rb
sed -i "s/EMAIL/${email}/g" /var/www/${db_name}/config/config.rb
echo "DONE WITH ASPACE DIR!"

#APACHE CONF

cp -r ./instance.conf.template /etc/apache2/sites-available/${db_name}.conf
sed -i "s/INSTANCE/${db_name}/g" /etc/apache2/sites-available/${db_name}.conf
sed -i "s/XX/${instance_number}/g" /etc/apache2/sites-available/${db_name}.conf
sed -i "s/DOMAIN/${domain}/g" /etc/apache2/sites-available/${db_name}.conf
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

if [[ $version = "3.3.1"  ]]
then
sudo -H -u solr bash -c "/opt/solr/bin/solr create -c ${db_name} -d archivesspace331"
echo "AppConfig[:solr_url] = 'http://localhost:8983/solr/${db_name}'" >> /var/www/${db_name}/config/config.rb
echo "DONE WITH SOLR!"
fi

if [[ $version = "3.4.0"  ]]
then
sudo -H -u solr bash -c "/opt/solr/bin/solr create -c ${db_name} -d archivesspace340"
echo "AppConfig[:solr_url] = 'http://localhost:8983/solr/${db_name}'" >> /var/www/${db_name}/config/config.rb
echo "DONE WITH SOLR!"
fi

if [[ $version = "3.4.1"  ]]
then
sudo -H -u solr bash -c "/opt/solr/bin/solr create -c ${db_name} -d archivesspace340"
echo "AppConfig[:solr_url] = 'http://localhost:8983/solr/${db_name}'" >> /var/www/${db_name}/config/config.rb
echo "DONE WITH SOLR!"
fi

if [[ $version = "3.5.0"  ]]
then
sudo -H -u solr bash -c "/opt/solr/bin/solr create -c ${db_name} -d archivesspace350"
echo "AppConfig[:solr_url] = 'http://localhost:8983/solr/${db_name}'" >> /var/www/${db_name}/config/config.rb
echo "DONE WITH SOLR!"
fi

if [[ $version = "3.5.1"  ]]
then
sudo -H -u solr bash -c "/opt/solr/bin/solr create -c ${db_name} -d archivesspace351"
echo "AppConfig[:solr_url] = 'http://localhost:8983/solr/${db_name}'" >> /var/www/${db_name}/config/config.rb
echo "DONE WITH SOLR!"
fi

# ASpace 4 needs a newer version of solr, which we'll get from Docker.
if [[ $version = "4.0.0"  ]]
then
docker run -d -p ${instance_number}983:8983 --name ${db_name}-solr -t archivesspace/solr:4.0.0
docker exec -it --user solr ${db_name}-solr bin/solr create_core -c ${db_name} -d archivesspace

echo "AppConfig[:solr_url] = 'http://localhost:${instance_number}983/solr/${db_name}'" >> /var/www/${db_name}/config/config.rb
echo "DONE WITH SOLR!"
fi

if [[ $version = "4.1.0"  ]]
then
docker run -d -p ${instance_number}983:8983 --name ${db_name}-solr -t archivesspace/solr:4.1.0
docker exec -it --user solr ${db_name}-solr bin/solr create_core -c ${db_name} -d archivesspace

echo "AppConfig[:solr_url] = 'http://localhost:${instance_number}983/solr/${db_name}'" >> /var/www/${db_name}/config/config.rb
echo "DONE WITH SOLR!"
fi

#DOCKER CONTAINER

if [[ $ram = "2048"  ]]
then
  cpu="1"
fi

if [[ $ram = "4096"  ]]
then
  cpu="2"
fi

if [[ $ram = "8192"  ]]
then
  cpu="4"
fi

if [[ $ram = "16384"  ]]
then
  cpu="6"
fi

mkdir /root/containers/${db_name}
cp ./docker-compose.yml.template /root/containers/${db_name}/docker-compose.yml

sed -i "s/INSTANCE/${db_name}/g" /root/containers/${db_name}/docker-compose.yml
sed -i "s/RAM/${ram}/g" /root/containers/${db_name}/docker-compose.yml
sed -i "s/CPU/${cpu}/g" /root/containers/${db_name}/docker-compose.yml
sed -i "s/VER/${version}/g" /root/containers/${db_name}/docker-compose.yml

docker compose -f /root/containers/${db_name}/docker-compose.yml up -d

