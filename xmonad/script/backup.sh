#!/bin/sh

if ! ps -aux | grep "[/usr/bin/perl] -w /usr/bin/rsnapshot daily" -q;  
then
    bkp=""
else
    bkp="Backup"
fi

echo $bkp

exit 0
