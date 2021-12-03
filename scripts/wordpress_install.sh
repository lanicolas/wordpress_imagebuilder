#!/bin/bash

##############################################
#       Wordpress Ubuntu Installation        #
##############################################

export DEBIAN_FRONTEND="noninteractive"  
db_root_pwd=dbpassword    
wordpress_db=wordpressdb

apt-get update -y  

apt-get install apache2 apache2-utils -y  
systemctl start apache2  
systemctl enable apache2  

apt-get install -y php php-mysql libapache2-mod-php
debconf-set-selections <<< "mysql-server mysql-server/root_password password $db_root_pwd"  
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $db_root_pwd"  
apt-get install -y mysql-client mysql-server unzip

rm /var/www/html/index.*  
curl -O https://wordpress.org/latest.zip
unzip latest.zip
mv wordpress/* /var/www/html/  
chown -R www-data:www-data /var/www/html/  
chmod -R 755 /var/www/html/  

mysql -uroot -p$db_root_pwd <<EOF 
CREATE DATABASE $wordpress_db;  
GRANT ALL PRIVILEGES ON $wordpress_db.* TO 'root'@'localhost' IDENTIFIED BY '$db_root_pwd';  
FLUSH PRIVILEGES;  
EXIT  
EOF  

mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php  
sed -i "s/database_name_here/$wordpress_db/g" /var/www/html/wp-config.php  
sed -i "s/username_here/root/g" /var/www/html/wp-config.php  
sed -i "s/password_here/$db_root_pwd/g" /var/www/html/wp-config.php   

a2enmod rewrite  
php5enmod mcrypt  

apt-get install phpmyadmin -y  

echo 'Include /etc/phpmyadmin/apache.conf' >> /etc/apache2/apache2.conf  

service apache2 restart  
service mysql restart  
