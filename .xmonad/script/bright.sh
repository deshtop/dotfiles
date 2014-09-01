#!/bin/sh

bright=`xbacklight -get | cut -d . -f 1`
echo $bright

exit 0
