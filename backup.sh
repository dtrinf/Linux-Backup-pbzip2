#!/bin/bash
# A UNIX / Linux shell script to backup dirs (linux)
# This script make both full and differential backups.
# You can run script at midnight or early morning each day using cronjons.
# Script must run as root or configure permission via sudo.
# -------------------------------------------------------------------------
# Copyright (c) 2012 David Trigo <david.trigo@gmail.com>
# This script is licensed under GNU GPL version 3.0 or above
# -------------------------------------------------------------------------
# Last updated on : June-2012 - Script created.
# -------------------------------------------------------------------------
LOGBASE="/var/tmp/log"
 
# Backup dirs
BACKUP_ROOT_DIR="/home/david/documentacion"

# Backup destination dir
BACKUP_DIR="/home/david/borrar/"

# Exclude file
TAR_ARGS=""
EXCLUDE_CONF="/root/.backup.exclude.conf"

# Backup Log file
LOGFILE=$LOGBASE/$NOW.backup.log
 
# Path to binaries

# Check to see if pbzip2 is already on path; if so, set BZIP_BIN appropriately 
type -P pbzip2 &>/dev/null && export BZIP_BIN=$(which pbzip2)
# Otherwise, default to standard bzip2 binary
if [ -z $BZIP_BIN ]; then
  export BZIP_BIN=$(which bzip2)
fi

MKDIR=/bin/mkdir

# -------------------------------------------------------------------------
 
# Get todays day like 1, 2, .., 7; 1 is Monday
NOW=$(date +"%u")
TODAY_DATE=$(date +%F)
YESTERDAY_DATE=$(date +%F -d "$NOW day ago")
LAST_FULL_BACKUP_DATE=$(date +%F -d "$NOW day ago")

# Backup filename
TODAY_FILENAME="$TODAY_DATE.tbz"
YESTERDAY_FILENAME="$YESTERDAY_DATE.tbz"
LAST_FULL_BACKUP_FILENAME="$LAST_FULL_BACKUP_DATE.tbz"
 

 
# ------------------------------------------------------------------------
# Excluding files when using tar
# Create a file called $EXCLUDE_CONF using a text editor
# Add files matching patterns such as follows (regex allowed):
# /home/david/iso
# /home/david/*.cpp~
# ------------------------------------------------------------------------
[ -f $EXCLUDE_CONF ] && TAR_ARGS="-X $EXCLUDE_CONF"
 
#### Custom functions #####
# Make a full backup
full_backup(){
	local old=$(pwd)
	cd /
	tar  $TAR_ARGS -cpf $BACKUP_DIR$TODAY_FILENAME --use-compress-prog=$BZIP_BIN $BACKUP_ROOT_DIR
	cd $old
}
 
# Make a  differential backup
differential_backup(){
	local old=$(pwd)
	cd /
	tar  $TAR_ARGS -cpf $BACKUP_DIR$TODAY_FILENAME -N $BACKUP_DIR$LAST_FULL_BACKUP_FILENAME --use-compress-prog=$BZIP_BIN $BACKUP_ROOT_DIR
	cd $old
}

# Make a  incremental backup
incremental_backup(){
	local old=$(pwd)
	cd /
	tar  $TAR_ARGS -cpf $BACKUP_DIR$TODAY_FILENAME -N $BACKUP_DIR$YESTERDAY_FILENAME --use-compress-prog=$BZIP_BIN $BACKUP_ROOT_DIR
	cd $old
}
 
# Make sure all dirs exits
verify_backup_dirs(){
	local s=0
	for d in $BACKUP_ROOT_DIR
	do
		if [ ! -d /$d ];
		then
			echo "Error : /$d directory does not exits!"
			s=1
		fi
	done
	# if not; just die
	[ $s -eq 1 ] && exit 1
}
 
#### Main logic ####
 
# Make sure log dir exits
[ ! -d $LOGBASE ] && $MKDIR -p $LOGBASE
 
# Verify dirs
verify_backup_dirs
 
# Okay let us start backup procedure
# If it is Sunday make a full backup;
# For Mon to Fri make a differential backup
# Saturday no backups
case $NOW in
	7)	full_backup;;
	1|2|3|4|5)	differential_backup;;
	*)	;;
esac > $LOGFILE 2>&1
