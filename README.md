# Current Application Procedure

The application is a Docker compose project with the following containers:

| Container       | Purpose/Notes                                                                                             |
|-----------------|-----------------------------------------------------------------------------------------------------------|
| traefik         | A reverse proxy that routes inbound traffic                                                               |
| mariadb         | The official database conatiner that runs database server, operating on a volume that should be provided. |
| nextcloudrunner | A custom image that contains the dependencies to run a nextcloud installation.                            |

Steps to initialise:

1. Set environment variables. 
Make a copy of the sample.env file called `runtime.env` and populate the values for the database location and NextCloud install location.

2. Create the database location wherever you defined it in the env file. (Permissions?)
Initialise DB? Need the container.

3. Copy the Nextcloud install to the location specified in the env file. Can be in a script
- Download the tar-ball
- extract
- Move to location
- Change ownership
 



