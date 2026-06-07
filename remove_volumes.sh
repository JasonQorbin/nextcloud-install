#! /bin/bash

directory_name=$(basename "$PWD")

echo "Removing named volumes used by the application:"
docker volume rm "${directory_name}_nextcloud_config"
docker volume rm "${directory_name}_nextcloud_user_data"
docker volume rm "${directory_name}_nextcloud_themes"
docker volume rm "${directory_name}_nextcloud_install"
docker volume rm "${directory_name}_maria_database_volume"
echo "Done."
