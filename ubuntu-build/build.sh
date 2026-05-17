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
apt-get install -y php8.3 php8.3-xml php8.3-curl php8.3-gd php-json php8.3-mbstring php8.3-zip php8.3-mysql

echo -e "${GREEN}Installing recommended PHP modules${DEFAULT_COLOUR}"
apt-get install -y php8.3-bz2 php8.3-intl php8.3-smbclient php8.3-bcmath php8.3-gmp php-redis php-imagick

# Configure PHP settings per Nextcloud recommendations
PHP_INI="/etc/php/8.3/apache2/php.ini"
# Change the memory limit in the configuration file
sed -i 's/.*memory_limit.*/memory_limit = 512M/' $PHP_INI
# Disable PHP output buffering per nextcloud recommendations
sed -i 's/.*output_buffering.*/output_buffering = off/' $PHP_INI
# Set the timezone in the PHP config in case it cannot read the system time zone. 
sed -i 's|;date.timezone =|date.timezone = ${TZ}|' $PHP_INI
sed -i 's/;opcache.enable=1/opcache.enable=1/g' $PHP_INI
sed -i 's/;opcache.enable_cli=0/opcache.enable_cli=1/g' $PHP_INI
sed -i 's/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=16/g' $PHP_INI
# Set the number of PHP scripts that can be cached in memory to 10000
sed -i 's/;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=10000/g' $PHP_INI
# Set the amount of memory for caching compiled bytecode 128MB
sed -i 's/;opcache.memory_consumption=128/opcache.memory_consumption=128/g' $PHP_INI
# Set compiled bytecode to retain comments. Essential to allow the database abstraction layer (Doctrine) to parse metadata annotations
sed -i 's/;opcache.save_comments=1/opcache.save_comments=1/g' $PHP_INI
sed -i 's/;opcache.revalidate_freq=2/opcache.revalidate_freq=60/g' $PHP_INI

# Install ffmpeg to allow for meadia playback. This is a large package.
echo -e "${GREEN}Installing ffmpeg${DEFAULT_COLOUR}"
apt-get install -y ffmpeg

# Install libreoffice to allow opening of office-type files
echo -e "${GREEN}Installing LibreOffice${DEFAULT_COLOUR}"
apt-get install -y libreoffice


echo -e "${GREEN}Installing Apache2${DEFAULT_COLOUR}"
apt-get install -y apache2
