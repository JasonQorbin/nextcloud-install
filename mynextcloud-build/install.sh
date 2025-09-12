#!/bin/bash
# Load environment variables from .env file only if the file exists
[ ! -f .env ] || export $(grep -v '^#' .env | xargs)

# SERVER_NAME and DOWNLOAD_LINK are required variables. Exit if they are not present.
if [[ -z "${SERVER_NAME}" ]]; then
  echo "SERVER_NAME environment variable containing the qualified name of the server is required"
  exit 1
fi

if [[ -z "${DOWNLOAD_LINK}" ]]; then
  echo "DOWNLOAD_LINK environment variable containing the link to the Nextcloud tarball is required"
  exit 1
fi

NC_SERVER_NAME="${SERVER_NAME}"
NC_DOWNLOAD_LINK="${DOWNLOAD_LINK}"

# Setting up variables:
file_name=$(basename $NC_DOWNLOAD_LINK)
document_root=/var/www/nextcloud
GREEN='\033[0;32m'
RED='\033[0;31m'
DEFAULT_COLOUR='\033[0m'


echo -e "${GREEN}Updating system${DEFAULT_COLOUR}"
apt-get update -y
apt-get install -y software-properties-common
add-apt-repository ppa:ondrej/php -y
add-apt-repository ppa:ondrej/apache2 -y
apt-get install -y nano wget
apt-get upgrade -y

# Install tzdata and set timezone so that the installation doesn't get interrupted.
# If the TIME_ZONE environment variable has not been set then use UCT as the default.
if [[ -z "${TIME_ZONE}" ]]; then
    TIME_ZONE="UCT"
fi

DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends tzdata

timedatectl set-timezone ${TIME_ZONE}

echo -e "${GREEN}Installing PHP and required modules${DEFAULT_COLOUR}"
apt-get install -y php8.2 php8.2-xml php8.2-curl php8.2-gd php-json php8.2-mbstring php8.2-zip php8.2-mysql

echo -e "${GREEN}Installing recommended PHP modules${DEFAULT_COLOUR}"
apt-get install -y php8.2-bz2 php8.2-intl php8.2-smbclient php8.2-bcmath php8.2-gmp php8.2-redis php8.2-imagick

# Change the memory limit in the configuration file per Nextcloud recommendations
sed -i 's/.*memory_limit.*/memory_limit = 512M/' /etc/php/8.2/apache2/php.ini
# Disable PHP output buffering per nextcloud recommendations
sed -i 's/.*output_buffering.*/output_buffering = off/' /etc/php/8.2/apache2/php.ini

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
nextcloud_config=/etc/apache2/sites-available/Nextcloud.conf
touch $nextcloud_config

echo "LoadModule ssl_module modules/mod_ssl.so

<VirtualHost *:80>
   ServerName ${SERVER_NAME}
   Redirect permanent / https://${SERVER_NAME}/
</VirtualHost>

<VirtualHost *:443>
        ServerName ${SERVER_NAME}
        DocumentRoot $document_root
        SSLEngine on
        SSLCertificateFile      /etc/ssl/certs/ssl-cert-snakeoil.pem
        SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key

        <IfModule mod_headers.c>
                Header always set Strict-Transport-Security \"max-age=15552000; includeSubDomains\"
        </IfModule>

        <Directory $document_root>
                Require all granted
                AllowOverride All
                Options FollowSymLinks MultiViews

                <IfModule mod_dav.c>
                        Dav off
                </IfModule>
        </Directory>

</VirtualHost>" >> $nextcloud_config

# Enable the new site
a2ensite Nextcloud.conf

# Disable the default site
a2dissite 000-default.conf

# Enable the required apache2 modules
a2enmod rewrite
a2enmod headers
a2enmod env
a2enmod dir
a2enmod mime
a2enmod ssl

# Nextcloud crob jobs

echo -e "${GREEN}Setting up Nextcloud cron jobs${DEFAULT_COLOUR}"
apt install cron -y
(crontab -u www-data -l 2>/dev/null; echo "*/5  *  *  *  * php -f /var/www/nextcloud/cron.php") | crontab -u www-data -


echo -e "${GREEN}Creating startup script${DEFAULT_COLOUR}"

pushd /usr/local/bin
touch startup.sh
echo "#!/bin/bash
service apache2 start
sleep infinity" >> startup.sh
chmod u+x startup.sh
chmod o+x startup.sh

echo -e "${GREEN}Done${DEFAULT_COLOUR}"
