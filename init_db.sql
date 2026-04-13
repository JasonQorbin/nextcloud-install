-- Script to set up the database and user that NextCloud will use.
-- This srcipt is meant to be run from the init_db.sh script, which check that the prerequisites are met.
-- 
-- Assumes that the user you are running the script as has the privileges to:
-- - Create databases.
-- - Create users.
-- - Assign privileges.
--
-- Expects the following environment variable to be set:
-- - NC_DB_NAME -> the name of the database to create.
-- - NC_DB_USER_NAME -> the name of the database user to create.
-- - NC_DB_PASSWORD -> The password of the user.

SET @db_name = '${NC_DB_NAME}';
SET @user_name = '${NC_DB_USER_NAME}';
SET @user_password = '${NC_DB_PASSWORD}';

CREATE DATABASE IF NOT EXISTS @db_name;

CREATE USER @user_name@'nextcloud' IDENTIFIED BY @user_password;

GRANT ALL PRIVILEGES ON @db_name.* TO @user_name@'localhost';

FLUSH PRIVILEGES;
