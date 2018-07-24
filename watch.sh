#!/bin/bash

[[ "$TRACE" ]] && set -x

set -e

function error_exit {
  echo "${1:-"Unknown Error"}" 1>&2
  exit 1
}

PROGNAME=$0
REMOTE=$1
LOCAL="/data/backup_files"

function restore {
  echo "s3 restoring $REMOTE => $LOCAL"
  if ! aws s3 sync "$REMOTE" "$LOCAL"; then
    error_exit "s3 restore failed"
  else
    echo "s3 restore complete"
    if [[ -z `ls -A $LOCAL` ]]; then
      echo "no s3 backups to restore, skipping"
      return 0
    else
      if ! ./restore.sh; then
        error_exit "ghost restore failed"
      else
        echo "ghost restore completed"
        return 0
      fi
    fi
  fi  
}

function backup {
  echo "backup ghost"
  if [ -e "data/data/ghost.db" ]; then
    echo "ghost.db located, attempting ghost backup"  
    if ./backup.sh; then
      echo "s3 backup $LOCAL => $REMOTE"
      if ! aws s3 sync "$LOCAL" "$REMOTE" --delete; then
        echo "backup failed" 1>&2
        return 1
      else 
        return 0
      fi
    fi
  else 
    echo "can't find ghost.db, no backup"
    return 1
  fi
}

function final_backup {
  echo "final backup ghost"
  if [ -e "data/data/ghost.db" ]; then
    echo "ghost.db located, attempting final ghost backup"  
    if ./backup.sh; then
      echo "s3 backup $LOCAL => $REMOTE"
      while ! aws s3 sync "$LOCAL" "$REMOTE" --delete; do
        echo "backup failed, will retry" 1>&2
        sleep 1
      done
      exit 0
    fi
  else 
    echo "can't find ghost.db, no backup"
    exit 1
  fi
}

function idle {
  echo "ready"
  while true; do
    sleep ${BACKUP_INTERVAL:-42} &
    wait $!
    echo "..."
    [ -n "$BACKUP_INTERVAL" ] && backup
  done
}

echo "ghost-backup-s3 initialising..."
if [ "$BACKUP_ONLY" == "false" ]; then
  echo "Initial restore..."
  restore
else
  echo "BACKUP_ONLY=true so skipping initial restore"
fi

trap final_backup SIGHUP SIGINT SIGTERM
trap "backup; idle" USR1

idle
