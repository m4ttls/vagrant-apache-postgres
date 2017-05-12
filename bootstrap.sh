#!/usr/bin/env bash

# Use single quotes instead of double quotes to make it work with special-character passwords
PASSWORD='12345678'
PROJECTFOLDER='myproject'

# create project folder
sudo mkdir "/var/lib/tomcat/webapps/${PROJECTFOLDER}"

# update / upgrade
sudo apt-get update
sudo apt-get -y upgrade

# install apache 2.5 and php 5.5
sudo apt-get install -y default-jdk
sudo groupadd tomcat
sudo useradd -s /bin/lase -g tomcat -d /opt/tomcat tomcat
cd /tmp
curl -O http://apache.dattatec.com/tomcat/tomcat-8/v8.5.15/bin/apache-tomcat-8.5.15.tar.gz
sudo tar xzvf apache-tomcat-8*tar.gz -C /opt/tomcat --stip-components=1
cd /opt/tomcat
sudo chgrp -R tomcat /opt/tomcat
sudo chmod -R g+r conf
sudo chmod g+x conf
sudo chown -R tomcat webapps/ work/ temp/ logs/

# postgres
sudo apt-get install -y postgresql postgresql-contrib

POSTGRE_VERSION=9.3

# listen for localhost connections
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/$POSTGRE_VERSION/main/postgresql.conf

# identify users via "md5", rather than "ident", allowing us to make postgres
# users separate from system users. "md5" lets us simply use a password
echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a /etc/postgresql/$POSTGRE_VERSION/main/pg_hba.conf
sudo service postgresql start

# create new user "root" with defined password "root" not a superuser
sudo -u postgres psql -c "CREATE ROLE root LOGIN UNENCRYPTED PASSWORD '$PASSWORD' NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;"

# create new database "database"
sudo -u postgres psql -c "CREATE DATABASE database"

sudo service postgresql restart

# install mysql and give password to installer
#sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
#sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
#sudo apt-get -y install mysql-server
#sudo apt-get install php5-mysql

# install phpmyadmin and give password(s) to installer
# for simplicity I'm using the same password for mysql and phpmyadmin
#sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
#sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $PASSWORD"
#sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $PASSWORD"
#sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $PASSWORD"
#sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
#sudo apt-get -y install phpmyadmin

# setup hosts file
VHOST=$(cat <<EOF
<VirtualHost *:80>
    DocumentRoot "/var/www/html/${PROJECTFOLDER}"
    <Directory "/var/www/html/${PROJECTFOLDER}">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-available/000-default.conf

# enable mod_rewrite
sudo a2enmod rewrite

# restart apache
service apache2 restart

# install git
sudo apt-get -y install git

# install Composer
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
