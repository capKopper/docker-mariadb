# Changelog

## 1.1.5 (2015-10-15)

#### MariaDB
+ update mariadb package version to '10.0.21'


## 1.1.4 (2015-10-15)

### Configuration
+ fix the creation of the temporary file when using 'DB_NAME' variable
+ ability to change access rights on the database


## 1.1.3 (2015-07-24)

#### MariaDB
+ update mariadb package version

### Configuration
+ add 'DB_CREATE_MODE' option
+ ability to create databases with a file using 'DB_NAME_FILE' variable.

### Tools
+ add 'create_db.sh'


## 1.1.0 (2015-04-20)

#### Configuration
+ ability to create several database with 'DB_NAME' environment variable.

#### Startup
+ changing supervisor with runit.