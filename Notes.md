# Install methodology

1. The Nextcloud image has a copy of the installation baked into it and placed at /usr/local/nextcloud. This version 
   will be baked into that location with the correct ownership and file permissions for runtime because this becomes
   an issue for development in some Docker implementations.
2. To maintain state, the Nextcloud image will expect host volumes for the installation files, user data, themes, apps
   and the config folders. The installation files need to be saved to allow for the application to update itself via the
   web interface.
3. The image contains a startup script that the image runs on startup. The startup script first searches for the
   following:
   - It checks if the container is in a "new install state". This is evidenced by the nextcloud files outside the /apps,
     /themes, and config folders are present. On of the files that we can count on being there is `version.php` because
     the Nextcloud updater looks for this file to check which version the current set of files represents and which
     database and config versions it can be used to upgrade from. If this file is missing then there is likely no
     existing installation and the script needs to "install" it by using rsync to copy over the files from the baked-in
     installation.
   - On the other hand, if there is an installation there are two options
     - Either we just updated the Nextcloud image with the intention to upgrade the version that is in the host volume
       or;
     - The admin has been upgrading by this or other means and the host volume's version is equal to or greater than
       the baked-in version. In this case we simply use the version in the host volume, but print a meaningful log
       message in the container's STDOUT that can be caught somewhere.
4. After this check the file permissions are checked/corrected again and then the web server can be started.

## Notes

- The rsync command must be done with the `-a` (archive) metaflag that sets various other flags to ensure that the file
  ownership and permissions remain intact.
- Need to deal with the environment variable to set a development mode. The development mode would override the logic
  that checks for a clean install or an upgradable installation. If we are in deelopment mode we should just use the
  install in the mounted volume and not overwrite it with the the baked in version. Dev mode should be the default. That
  means that to test the upgrading logic we either need to force the container to production mode or we need to have a
  second test variable to allow it it to happen in Dev mode. The logic would then be:
  
```pseudocode
    if (version.php is missing) {
    
        //New Install
        Copy_the_embedded_install_with_rsync();
        
    } else if (volume has older version && embedded version can upgrade from the volume version) {
    
        if (in_prod_mode || in_dev_mode && test_upgrade_allowed_flag) {
            Copy_the_embedded_install_with_rsync_excluding_state_folders();
        }    
    } 
```
