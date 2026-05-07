#!/bin/bash
set -e
SOURCE_DIR="/usr/src/nextcloud"
TARGET_DIR="/var/www/nextcloud"

# Extract the version numbers using a custom function.
# Use '|| true' to prevent set -e from killing the script if the file is missing
# Return a default value of "0.0.0" if the file is missing or invalid (doesn't have a version string)
get_version() {
    grep '$OC_VersionString =' "$1" 2>/dev/null | cut -d "'" -f 2 || echo "0.0.0"
}

IMG_VER=$(get_version "$SOURCE_DIR/version.php")
VOL_VER=$(get_version "$TARGET_DIR/version.php")

echo "Application versions found:"
echo "Image Version: $IMG_VER | Volume Version: $VOL_VER"

if [ "$IMG_VER" = ""]; then
    sleep infinity
fi

# Decide whether to copt or not.
if [ "$VOL_VER" = "0.0.0" ]; then
    # If we can't find the volume version them assume we are doing a fresh install.
    echo "Fresh install detected. Initializing..."
    rsync -a --stats "$SOURCE_DIR/" "$TARGET_DIR/"
    echo "Synchronization complete"

elif [ "$(printf '%s\n%s' "$VOL_VER" "$IMG_VER" | sort -V | head -n1)" = "$VOL_VER" ] && [ "$VOL_VER" != "$IMG_VER" ]; then
    # Translation: If the Volume Version is the 'smaller' one when sorted, it means the Image is newer. Time to upgrade.
    # Copy over the newer image version and skip the stateful folders.
    echo "Image is newer than Volume. Upgrading core files..."
    rsync -a --delete --stats \
        --exclude='/data' \
        --exclude='/config' \
        --exclude='/apps' \
        --exclude='/themes' \
        "$SOURCE_DIR/" "$TARGET_DIR/"
    echo "Synchronization complete"
        
else
    # If the Volume is newer (Web-Updated) or identical, copying the image version would cause a regression so
    # DO NOTHING.
    if [ "$VOL_VER" = "$IMG_VER" ]; then
        echo "Current application version is up-to-date with the image."
    else 
        echo "Current application version is newer than the image version. Skipping sync."
    fi
fi

# Final permission safety check
# Swallowing errors to prevent failure on Arch dev machine.
chown -R www-data:www-data "$TARGET_DIR" 2>/dev/null || true

service apache2 start
sleep infinity
