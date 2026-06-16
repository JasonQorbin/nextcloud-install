#! /bin/bash

directory_name=$(basename "$PWD")

echo "Removing named volumes used by the application:"
docker volume rm "${directory_name}_nextcloud-config"
docker volume rm "${directory_name}_nextcloud-user-data"
docker volume rm "${directory_name}_nextcloud-themes"
docker volume rm "${directory_name}_nextcloud-install"
docker volume rm "${directory_name}_maria-database-volume"
docker volume rm "${directory_name}_redis-data"
echo "Done."
