# My Nextcloud Deployment

This is the install script for my deployment of the Nextcloud server. This is run on a single VPS instance for my own
personal use and comsumption. I had previously relied on third party images and apps to run my Nextcloud on a home
server and the delays in updates and limitations of a dynamic IP address, combined with how integral Nextcloud has
become to my life for my document storage needs alone. I decided that it was time to deploy my own server.

## Application structure and build process

The application is a Docker compose project with the following containers:

| Container       | Purpose/Notes                                                                                             |
|-----------------|-----------------------------------------------------------------------------------------------------------|
| traefik         | A reverse proxy that routes inbound traffic                                                               |
| mariadb         | The official database conatiner that runs database server, operating on a volume that should be provided. |
| redis           | Standard redis image. Nextcloud gives warnings if it doesn't have a cache.                                |
| nextcloudrunner | A custom image that contains the dependencies to run a nextcloud installation.                            |

The nextcloud image is built in two steps.

### Ubuntu base container

First we create an image called `ubuntu-upgraded:24.04`. This is a standard `ubuntu:24.04` image that has all the
required php dependencies installed and all of the reccomended dependencies that I care about installed. This first
step primarily exists to reduce the build times I had to sit through during development.

#### Build steps:

1. `cd ubuntu-build`
2. `docker build -t ubuntu-upgraded:2404 .`

### The "nextcloudrunner"

Next we create the container that will actually run the server application. It's called a "runner" because it doesn't
actually keep the nextcloud files in the web root. The image keeps the files in `/usr/local/nextcloud`.  The compose
file then creates a volume at the web root and when it starts it first checks if it looks like there is a nextcloud
install already in the volume, if not it rsyncs the contents of `/usr/local/nextcloud` into that root. This was done for
two reasons:

1. The nextcloud installation file are actually part of the application state.

The nextcloud application has a 'self-updater' function that allows the admin user to click a button on the web
interface to update the server in place. When this happens is replaces the installation files and makes updates to the
database and config file. If we just put the installation files at the web root in the image, when the container
restarted it would revert those changes back to the old version, but the database and config file would report and
expect a different, higher version, breaking the installation. The application therefore needs to be able to "change
itself", making it part of the mutable state.

2. This allows me to force an update by swapping out an image with a higher version.

If the container sees that the image has a higher version than the volume, it means I did an update and it will rsync
the new version over the old. I still have to do the manual db upgrade but this give me the flexibility to do so.

#### Build steps

1. `cd mynextcloud-build`
2. `cp sample.env .env`
3. Edit the new `.env` file by adding the download link to the nextcloud version you want to include.
4. `docker build -t nextcloudrunner:<tag> .`  
**The convention is for the tag to match the version of Nextcloud**


## Running the application

Once the above two images exist on the target system:

1. Set the required environment variables. 
   Make a copy of the `sample.env` file and call it `runtime.env` and populate the values for the database and
   and hostname and certificate settings.
2. Start the application with docker compose up.

