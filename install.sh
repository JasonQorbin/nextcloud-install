#!/bin/bash

# Load environment variables from .env file
[ ! -f .env ] || export $(grep -v '^#' .env | xargs)

if [[ -z "${DB_LOCATION}" ]]; then
    echo "Database location not specified. Using the mariadb default"
    use_default_db_location=true
else 
    use_default_db_location=false
    NC_DB_LOCATION="${DB_LOCATION}"
fi

if [[ -z "${SERVER_NAME}" ]]; then
  echo "ENV file not valid. Use the example file to make a new one."
  exit 1
else
    NC_SERVER_NAME="${SERVER_NAME}"
fi



# Note: Run this script with sudo privileges

# Setting up variables:
download_link=https://download.nextcloud.com/server/releases/nextcloud-26.0.13.tar.bz2
file_name=$(basename $download_link)
document_root=/var/www/nextcloud
GREEN='\033[0;32m'
RED='\033[0;31m'
DEFAULT_COLOUR='\033[0m'


echo -e "${GREEN}Updating system${DEFAULT_COLOUR}"
apt-get update -y && apt-get upgrade -y
apt-get install -y nano wget

echo -e "${GREEN}Installing Mariadb${DEFAULT_COLOUR}"
apt-get install -y mariadb-server

echo -e "${GREEN}Configuring database location${DEFAULT_COLOUR}"
if [ "$use_default_db_location" = false ] then;
    service mariadb stop
    mkdir $NC_DB_LOCATION
    cp -r /var/lib/mysql/* $NC_DB_LOCATION
    chown -R mysql:mysql $NC_DB_LOCATION
    echo "" >> /etc/mysql/mariadb.cnf
    echo "[server]" >> /etc/mysql/mariadb.cnf
    echo "datadir = $NC_DB_LOCATION" >> /etc/mysql/mariadb.cnf
    service mariadb start
fi

echo -e "${GREEN}Installing PHP and required modules${DEFAULT_COLOUR}"
apt-get install -y php php-xml php-curl php-gd php-json php-mbstring php-zip php-mysql

echo -e "${GREEN}Installing recommended PHP modules${DEFAULT_COLOUR}"
apt-get install -y php-bz2 php-intl php-smbclient php-bcmath php-gmp php-redis php-imagick

# Install ffmpeg to allow for meadia playback. This is a large package.
echo -e "${GREEN}Installing ffmpeg${DEFAULT_COLOUR}"
apt-get install -y ffmpeg

# Install libreoffice to allow opening of office-type files
echo -e "${GREEN}Installing LibreOffice${DEFAULT_COLOUR}"
apt-get install -y libreoffice


echo -e "${GREEN}Installing Apache2${DEFAULT_COLOUR}"
apt-get install -y apache2

echo -e "${GREEN}Create site configuration for Nextcloud${DEFAULT_COLOUR}"
service apache2 stop
# Create a site configuration from Nextcloud that uses the default self-signed certificate.
touch /etc/apache2/sites-available/NextCloud.conf
echo "<VirtualHost *:80>
	ServerName  $NC_SERVER_NAME
	Redirect permanent / https://$NC_SERVER_NAME	
</VirtualHost>

<VirtualHost *:443>
	DocumentRoot $document_root
	ServerName $NC_SERVER_NAME
	SSLCertificateFile	/etc/ssl/certs/ssl-cert-snakeoil.pem
	SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key

	<Directory $document_root/>
		Require all granted
		AllowOverride All
		Options FollowSymLinks MultiViews

		<IfModule mod_dav.c>
			Dav off
		</IfModule>
	</Directory>
	<IfModule mod_headers.c>
		Header always set Strict-Transport-Security \"max-age=15552000; includeSubDomains\"
	</IfModule>
 </VirtualHost>
" >> /etc/apache2/sites-available/NextCloud.conf

# Enable the new site
a2ensite NextCloud.conf

# Disable the default site
a2dissite 000-default.conf

# Enable the required apache2 modules
a2enmod rewrite
a2enmod headers
a2enmod env
a2enmod dir
a2enmod mime
a2enmod ssl

# Install NextCloud

pushd /tmp
wget $download_link
mkdir nc

echo -e "${GREEN}Unpacking NextCloud archive${DEFAULT_COLOUR}"
tar -xf $file_name -C ./nc

# Delete the theme and config folders because we will use our own
rm -rf ./nextcloud/themes
rm -rf ./nextcloud/config

# Move the extracted folder to the web server root
mv ./nc/nextcloud/ /var/www/

#change owner to www-data
chown -R www-data:www-data $document_root

service apache2 start

rm -r nc

# Remember to delete downloaded files
rm $file_name
