#!/bin/bash

set -e

NOW=`date '+%Y%m%d-%H%M'`

echo "Creating /data/backup_files"
mkdir -p /data/backup_files

# Backup the ghost DB (either sqlite3 or mysql)
backupDB () {
  # Test the env that is set if a mysql container is linked
  if [ -z $MYSQL_NAME ]; then
    # sqlite
    echo "creating ghost db archive (sqlite)..."
    cd data && sqlite3 data/ghost.db ".backup temp.db" && gzip -c temp.db > "backup_files/ghost-backup-db.gz" && rm temp.db
  else
    # mysql/mariadb
    echo "creating ghost db archive (mysql)..."
    # If container has been linked correctly, these environment variables should be available
    if [ -z "$MYSQL_ENV_MYSQL_USER" ]; then echo "Error: MYSQL_ENV_MYSQL_USER not set. Have you linked in the mysql/mariadb container?"; echo "Finished: FAILURE"; exit 1; fi
    if [ -z "$MYSQL_ENV_MYSQL_DATABASE" ]; then echo "Error: MYSQL_ENV_MYSQL_DATABASE not set. Have you linked in the mysql/mariadb container?"; echo "Finished: FAILURE"; exit 1; fi
    if [ -z "$MYSQL_ENV_MYSQL_PASSWORD" ]; then echo "Error: MYSQL_ENV_MYSQL_PASSWORD not set. Have you linked in the mysql/mariadb container?"; echo "Finished: FAILURE"; exit 1; fi
    mysqldump -h mysql --single-transaction -u $MYSQL_ENV_MYSQL_USER --password=$MYSQL_ENV_MYSQL_PASSWORD $MYSQL_ENV_MYSQL_DATABASE | 
     gzip -c > /data/backup_files/ghost-backup-db.gz
   fi

  echo "...completed: /data/backup_files/ghost-backup-db.gz"
}

# Backup the ghost static files (images, themes, apps etc) but not the /data directory (the db backup handles that)
backupGhost () {
  echo "creating ghost files archive..."
  tar cfz "/data/backup_files/ghost-backup-files.tar.gz" --directory='data' --exclude='data' --exclude='backup_files' . 2>&1 #Exclude the /data directory (we back that up separately)
  echo "...completed: /data/backup_files/ghost-backup-files.tar.gz"
}

backupGhost
backupDB

echo "completed backup to /data/backup_files at: $NOW"