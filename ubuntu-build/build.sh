#! /bin/bash

# Shortcut variables for coloured text
GREEN='\033[0;32m'
RED='\033[0;31m'
DEFAULT_COLOUR='\033[0m'

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
    TIME_ZONE="UTC"
fi

export DEBIAN_FRONTEND=noninteractive 

ln -snf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime
echo $TIME_ZONE > /etc/timezone

apt-get install -y tzdata


# Install PHP
echo -e "${GREEN}Installing PHP and required modules${DEFAULT_COLOUR}"
apt-get install -y \
    php8.4 \
    php8.4-xml \
    php8.4-curl \
    php8.4-gd \
    php8.4-mbstring \
    php8.4-zip \
    php8.4-mysql

echo -e "${GREEN}Installing recommended PHP modules${DEFAULT_COLOUR}"
apt-get install -y \
    php8.4-bz2 \
    php8.4-intl \
    php8.4-smbclient \
    php8.4-bcmath \
    php8.4-gmp \
    php8.4-redis \
    php8.4-imagick \
    php8.4-apcu \
    libmagickcore-6.q16-6-extra

# Configure PHP settings per Nextcloud recommendations for PHP 8.4
# We use a loop to apply these rules to BOTH Apache and CLI configurations
for RUNTIME in apache2 cli; do
    PHP_INI="/etc/php/8.4/${RUNTIME}/php.ini"
    
    if [ -f "$PHP_INI" ]; then
        echo -e "${GREEN}Configuring PHP 8.4 ${RUNTIME} settings...${DEFAULT_COLOUR}"
        
        # Base Performance Specs
        sed -i 's/^;\? \?memory_limit.*/memory_limit = 512M/' $PHP_INI
        sed -i 's/^;\? \?output_buffering.*/output_buffering = off/' $PHP_INI
        sed -i 's|^;\? \?date.timezone.*|date.timezone = '"${TIME_ZONE}"'|' $PHP_INI
        
        # Opcache Core Activation
        sed -i 's/^;\? \?opcache.enable\s*=.*/opcache.enable=1/' $PHP_INI
        sed -i 's/^;\? \?opcache.enable_cli\s*=.*/opcache.enable_cli=1/' $PHP_INI
        
        # Opcache Optimization (Fixes the Interned Strings Warning)
        sed -i 's/^;\? \?opcache.interned_strings_buffer\s*=.*/opcache.interned_strings_buffer=16/' $PHP_INI
        sed -i 's/^;\? \?opcache.max_accelerated_files\s*=.*/opcache.max_accelerated_files=10000/' $PHP_INI
        sed -i 's/^;\? \?opcache.memory_consumption\s*=.*/opcache.memory_consumption=128/' $PHP_INI
        sed -i 's/^;\? \?opcache.save_comments\s*=.*/opcache.save_comments=1/' $PHP_INI
        sed -i 's/^;\? \?opcache.revalidate_freq\s*=.*/opcache.revalidate_freq=60/' $PHP_INI
    fi
done

# Install ffmpeg to allow for meadia playback. This is a large package.
echo -e "${GREEN}Installing ffmpeg${DEFAULT_COLOUR}"
apt-get install -y ffmpeg

# Install libreoffice to allow opening of office-type files
echo -e "${GREEN}Installing LibreOffice${DEFAULT_COLOUR}"
apt-get install -y libreoffice


echo -e "${GREEN}Installing Apache2${DEFAULT_COLOUR}"
apt-get install -y apache2
