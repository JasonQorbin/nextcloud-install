#! /bin/bash

echo -e "${GREEN}Updating system${DEFAULT_COLOUR}"
apt-get update -y
apt-get install rsync -y
apt-get install -y software-properties-common
add-apt-repository ppa:ondrej/php -y
add-apt-repository ppa:ondrej/apache2 -y
apt-get install -y nano wget bzip2
apt-get upgrade -y

# Install tzdata and set timezone so that the installation doesn't get interrupted.
# If the TIME_ZONE environment variable has not been set then use UCT as the default.
if [[ -z "${TIME_ZONE}" ]]; then
    TIME_ZONE="UCT"
fi

export DEBIAN_FRONTEND=noninteractive 

ln -snf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime
echo $TIME_ZONE > /etc/timezone

apt-get install -y tzdata


# Install PHP
echo -e "${GREEN}Installing PHP and required modules${DEFAULT_COLOUR}"
apt-get install -y php8.2 php8.2-xml php8.2-curl php8.2-gd php-json php8.2-mbstring php8.2-zip php8.2-mysql

echo -e "${GREEN}Installing recommended PHP modules${DEFAULT_COLOUR}"
apt-get install -y php8.2-bz2 php8.2-intl php8.2-smbclient php8.2-bcmath php8.2-gmp php8.2-redis php8.2-imagick

# Change the memory limit in the configuration file per Nextcloud recommendations
sed -i 's/.*memory_limit.*/memory_limit = 512M/' /etc/php/8.2/apache2/php.ini
# Disable PHP output buffering per nextcloud recommendations
sed -i 's/.*output_buffering.*/output_buffering = off/' /etc/php/8.2/apache2/php.ini
# Set the timezone in the PHP config in case it cannot read the system time zone. 
sed -i "s|;date.timezone =|date.timezone = ${TZ}|" /etc/php/8.2/apache2/php.ini

# Install ffmpeg to allow for meadia playback. This is a large package.
echo -e "${GREEN}Installing ffmpeg${DEFAULT_COLOUR}"
apt-get install -y ffmpeg

# Install libreoffice to allow opening of office-type files
echo -e "${GREEN}Installing LibreOffice${DEFAULT_COLOUR}"
apt-get install -y libreoffice


echo -e "${GREEN}Installing Apache2${DEFAULT_COLOUR}"
apt-get install -y apache2
