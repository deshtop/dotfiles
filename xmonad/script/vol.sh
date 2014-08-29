#!/bin/sh

sound=`amixer get Master | awk '$0~/%/{print $6}' | tr -d '[]%' | head -1`
vol=`amixer get Master | awk '$0~/%/{print $5}' | tr -d '[]%' | head -1`

len="$((`echo $vol | wc -m` - 1))"

if [ "$sound" = "off" ]     # muted
then
    case $len in
        1)  vol='-' ;;
        2)  vol='--' ;;
        3)  vol='---' ;;
    esac 
fi

echo $vol

exit 0
