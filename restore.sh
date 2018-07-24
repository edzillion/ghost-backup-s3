#!/bin/bash

set -e

# Restore the database from the given archive file
restoreDB () {
  RESTORE_FILE=$1

  # Test the env that is set if a mysql container is linked
  if [ -z $MYSQL_NAME ]; then
    # sqlite
    echo "restoring data from sqlite dump file: $RESTORE_FILE"
    cd data/data && gunzip -c $RESTORE_FILE > temp.db && sqlite3 ghost.db ".restore temp.db" && rm temp.db
    echo "...restored ghost DB archive $RESTORE_FILE"
  else
    # mysql/mariadb
    echo "restoring data from mysql dump file: $RESTORE_FILE"
    # If container has been linked correctly, these environment variables should be available
    if [ -z "$MYSQL_ENV_MYSQL_USER" ]; then echo "Error: MYSQL_ENV_MYSQL_USER not set. Have you linked in the mysql/mariadb container?"; echo "Finished: FAILURE"; exit 1; fi
    if [ -z "$MYSQL_ENV_MYSQL_DATABASE" ]; then echo "Error: MYSQL_ENV_MYSQL_DATABASE not set. Have you linked in the mysql/mariadb container?"; echo "Finished: FAILURE"; exit 1; fi
    if [ -z "$MYSQL_ENV_MYSQL_PASSWORD" ]; then echo "Error: MYSQL_ENV_MYSQL_PASSWORD not set. Have you linked in the mysql/mariadb container?"; echo "Finished: FAILURE"; exit 1; fi
    gunzip < $RESTORE_FILE | mysql -u$MYSQL_ENV_MYSQL_USER -p $MYSQL_ENV_MYSQL_DATABASE -p$MYSQL_ENV_MYSQL_PASSWORD -h mysql || exit 1
    echo "...restored ghost DB archive $RESTORE_FILE"
  fi
  
  echo "db restore complete"
}

# Restore the ghost files (themes etc) from the given archive file
restoreGhost () {
  RESTORE_FILE=$1

  # echo "removing ghost files in /data"
  # rm -r data/apps/ data/images/ data/logs/ data/themes/ #Do not remove /data
  echo "restoring ghost files from archive file: $RESTORE_FILE"
  tar -xzf $RESTORE_FILE --directory='data' 2>&1

  echo "file restore complete"
}

# Attempt to restore ghost and db files
FILES_ARCHIVE="/data/backup_files/ghost-backup-files.tar.gz"
DB_ARCHIVE="/data/backup_files/ghost-backup-db.gz"

if [[ ! -f $FILES_ARCHIVE ]]; then
    echo "The ghost archive file $FILES_ARCHIVE does not exist. Aborting."
    exit 1
fi
if [[ ! -f $DB_ARCHIVE ]]; then
    echo "The ghost db archive file $DB_ARCHIVE does not exist. Aborting."
    exit 1
fi

echo "Restoring ghost files and db"
restoreGhost $FILES_ARCHIVE
restoreDB $DB_ARCHIVE

echo "Removing  /data/backup_files"
rm -rf /data/backup_files