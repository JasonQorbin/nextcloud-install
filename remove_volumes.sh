#! /bin/bash

# This script is a development tool. When testing things involving the named volumes it is useful to be able to 
# quickly delete all existing volumes, which is what this script does.

directory_name=$(basename "$PWD")

echo "Removing named volumes used by the application:"
docker volume rm "${directory_name}_nextcloud-config"
docker volume rm "${directory_name}_nextcloud-user-data"
docker volume rm "${directory_name}_nextcloud-themes"
docker volume rm "${directory_name}_nextcloud-install"
docker volume rm "${directory_name}_maria-database-volume"
docker volume rm "${directory_name}_redis-data"
echo "Done."
