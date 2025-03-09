# Nextcloud installation script

This script installs Nextcloud given the link to the relevant version. I made this because  I kept falling behind
on upgrading to the new major versions as they came out and automatic upgrade tool wasn't working for me (likely
permission issues...). When time came to upgrade (usually in 6 month intevals) I would have forgotten the steps I
took to do an install. This script does much of the heavy lifting of installing Nextcloud from scrtch in a new 
container.

The script installs mariadb, php (with all the required and optional modules that I use) and an apache2 web server,
all in the same container. This creates a self-contained installation. The nextcloud files will be placed in a 
separate folder called `nextcloud` next to the default document root of apache2 (i.e. it will be in /var/www/nextcloud)
and it will create a site configuration for this folder.

## How to use

1. Create a new docker container based on the Ubuntu:22.04 image (Nextcloud reccomends using the LTS version).
   - Setting up host volumes at this point in time is not necessary.
2. 'exec' into the container with the following command

```bash
sudo docker exec -it container_id /bin/bash
```
   - Use `sudo docker ps` to find the correct container id.

3. [Optional] Install a text editor like nano.
4. Place the install script somewhere. A good place is the `/tmp`. So either clone this repo in the container or
   use the text editor from the previous step to create the script file.
5. Make the script executable with `chmod u+x install.sh`.
6. Create a `.env` file by making a copy of the `.env.sample` file and filling in all the fields.
7. Run the script with `./install.sh`.

## SSL configuration

The current version all but requires that you use TLS. If you don't, it disables critical features like copying links
to the clipboard. In this regard I need to update the docker image to use the SLL configuration for the site but for
future installs, the configuration uses the self-signed certificate that comes with the apache2 installation. The
steps are:

1. Enable the SSL module of apache2 with `a2enmod ssl`
2. Apply the site configuration in this folder.
