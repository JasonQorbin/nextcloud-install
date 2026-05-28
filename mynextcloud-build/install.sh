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

#INSERT OS setup here

# Bake in a default copy of Nextcloud
embeddedInstallLocation=/usr/src/nextcloud
mkdir -p $embeddedInstallLocation
mkdir /tmp/install
echo -e "${GREEN}Downloading Nextcloud${DEFAULT_COLOUR}"
wget -P /tmp/install ${DOWNLOAD_LINK}
echo -e "${GREEN}Extracting Nextcloud${DEFAULT_COLOUR}"
tar -xjf /tmp/install/*.tar.bz2 -C $embeddedInstallLocation --strip-components=1
chown -R 33:33 $embeddedInstallLocation
rm -Rf /tmp/install


echo -e "${GREEN}Create site configuration for Nextcloud${DEFAULT_COLOUR}"
service apache2 stop
# Create a site configuration from Nextcloud that uses the default self-signed certificate.
http_config=/etc/apache2/sites-available/nc_http.conf
nextcloud_config=/etc/apache2/sites-available/Nextcloud.conf
conf_file=$(basename "$nextcloud_config")
touch $http_config

echo "<VirtualHost *:80>
    DocumentRoot /var/www/nextcloud
    ServerName localhost

    # Accept the proxy's routing without complaining about host mismatches
    ServerAlias *

    <Directory /var/www/nextcloud/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted

        <IfModule mod_dav.c>
            Dav off
        </IfModule>
    </Directory>

    # Logging profiles using standard stdout/stderr streams for Docker
    ErrorLog /proc/self/fd/2
    CustomLog /proc/self/fd/1 combined
</VirtualHost>" > $nextcloud_config

# Enable the new site
a2ensite $conf_file

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
(crontab -u www-data -l 2>/dev/null; echo "*/5  *  *  *  * /usr/bin/php8.3 -f /var/www/nextcloud/cron.php") | crontab -u www-data -

mv startup.sh /usr/local/bin/
pushd /usr/local/bin
chmod u+x startup.sh
chmod o+x startup.sh
popd

echo -e "${GREEN}Done${DEFAULT_COLOUR}"
