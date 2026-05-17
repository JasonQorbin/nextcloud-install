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
SET @hostname = 'nextcloud';
SET @userString = CONCAT(QUOTE(@user_name),'@',QUOTE(@hostname));

SET @sql = CONCAT('CREATE DATABASE IF NOT EXISTS `', @db_name,'`');

PREPARE tblStmt FROM @sql;
EXECUTE tblStmt;
DEALLOCATE PREPARE tblStmt;

SET @sql = CONCAT('CREATE USER ', @userString,' IDENTIFIED BY ',QUOTE(@user_password));

PREPARE userStmt FROM @sql;
EXECUTE userStmt;
DEALLOCATE PREPARE userStmt;


SET @sql = CONCAT('GRANT ALL PRIVILEGES ON `', @db_name, '`.* TO ', @userString);

PREPARE privStmt FROM @sql;
EXECUTE privStmt;
DEALLOCATE PREPARE privStmt;

FLUSH PRIVILEGES;
