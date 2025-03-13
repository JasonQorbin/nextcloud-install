# Nextcloud installation script

This script installs Nextcloud given the link to the relevant version. I made this because  I kept falling behind
on upgrading to the new major versions as they came out and automatic upgrade tool wasn't working for me (likely
permission issues...). When time came to upgrade (usually in 6 month intevals) I would have forgotten the steps I
took to do an install. This script does much of the heavy lifting of installing Nextcloud from scratch in a new 
container.

Yes, a **new container**. While it is possible to upgrade your installation by simply replacing the existing
installation with a new one and running the upgrader, I prefer to stop the old container and put it aside in case I goof
something up. Because fully upgrading NextCloud across a major version update often involves additional manual steps
like manual or script-based changes and optimizations to the database, knowing that you can always go back to a working
system and at worst you will have to revert your database using a snapshot takes a lot of the stress out of this
process. That being said, building the system from scratch everytime takes a while (10-20 mins on my machine) so I will
look at making an alternative script in the future for upgrading a installation in place which should work much faster.


The script installs mariadb, php (with all the required and optional modules that I use) and an apache2 web server,
all in the same container. This creates a self-contained installation. The nextcloud files will be placed in a 
separate folder called `nextcloud` next to the default document root of apache2 (i.e. it will be in /var/www/nextcloud)
and it will create a site configuration for this folder.

## How to use

1. Put the current installation in maintenance mode by changing the maintenance flag to true in the `config.php` file
   and then trying to access the web interface and confirming the that the maintenance message is being displayed.
2. Stop old container in docker/TrueNAS.
3. Take a snapshot of the NextCloud dataset and give it a useful name like "Before upgrade to NC 3# ...".
4. Create a new docker container based on the Ubuntu:22.04 image
   - Nextcloud reccomends using this specific LTS version of Ubuntu, this may change eventually so check the 
     documentation from time to time and adjust accordingly.
   - Setting up host volumes at this point in time is not necessary.
5. 'exec' into the container with the following command

```bash
sudo docker exec -it CONTAINER_ID /bin/bash
```
   - Use `sudo docker ps` to find the correct container id.

6. Install a text editor like nano. I suggest nano because we will be doing very simple text editing only and nano is
   very small compared to something like vi. Use what you like but you generally will not find yourself having to come
   back here very often at all which is why I prioritise the size of the installation.
7. Place the install script somewhere. A good place is the `/tmp`. So either clone this repo in the container or
   use the text editor from the previous step to create the script file.
8. Make the script executable by running `sudo chmod u+x install.sh`.
9. Create the required environment variables:
   - The easiest way to do this is to create a `.env` file which is a copy of the `.env.sample` file and replacing the
     "XXX"s where required or deleting lines you don't care about. Alternatively you can manually create the variables
     in your shell.
   - There are 2 required variables: 
      - `SERVER_NAME` which should be something like "myserver.mydomain.com". Nextcloud recommends putting it in a
      subdomain like this but you do what you what with your domains.
      - `DOWNLOD_LINK` which is the link to the tarball (i.e. `.tar.bz2` file) of the nextcloud install. These can be
      found at on the [Change Log](https://nextcloud.com/changelog/) page on the NextCloud website.
10. Run the script by typing `./install.sh`.
11. Exit the container and while it is still running, save it as a new image using
```bash
sudo docker commit CONTAINER_ID IMAGE_NAME:TAG
```
  - It's useful to make the tag the version number of Nextcloud.
12. Stop the container and delete it.
13. Create a new container that is based on the image you just made using the following paramters:
  - Set CMD to `/bin/sh`.
  - Set ARG to `/usr/local/bin/startup.sh`.
  - Set the host volumes as follows:

| Host Path/ Volume   | Mount path                    |
|---------------------|-------------------------------|
| Database            | Your chosen database location |
| Themes              | /var/www/nextcloud/themes     |
| Config              | /var/www/nextcloud/config     |
| Files               | /mnt/data                     |

  - If you chose not to specify a database location then your database will be in the default location for mariaDB i.e.
    `/var/lib/mysql`.  
14. Visit site to verifiy that it is running. You should see the message stating that the server is in maintenance 
    mode.
15. Perform the upgrade to migrate the database and upgrade the apps. There are two options here:
    - If you can have control over your clients and can thus afford to do the upgrade live, take the server out of
    maintenence mode by changing the maintenance flag to false in the `config.php` file. Then run the upgrader on
    the webpage
    - Or if you can't safely take the server out of maintenance mode,  run `./occ upgrade` from the command line
    instead and then Take it out of maintenance mode. This method is recommended by Nextcloud if you have a larger
    installtion (and thus a large database) because doing it via the web interface in this situation may cause the
    page to timeout.
16. Sometimes the there will be additional steps that need to be done that the upgrader is unable to. Check the
    Administration setting panel to see a list of the things that need to be done.

## SSL configuration

The current version all but requires that you use TLS. If you don't, it disables critical features like copying links
to the clipboard. This script uses the system's built-in self signed certificate which will cause a security message
to appear on on each client after an upgrade asking the user if they trust the server.

In future I will update the script to allow use of your own certificate. Feel free to modify the container image to 
do this for now.
