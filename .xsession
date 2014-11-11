#!/bin/sh

~/.screenlayout/layout.sh &                 # dual monitor layout 
xrdb -merge ~/.Xresources &                 # load setting for whole X  
xscreensaver -no-splash &                   # screen locking
mpd &                                       # music player daemon
eval "$(gpg-agent --daemon)" &              # start gpg-agent
compton --focus-exclude 'class_g = "URxvt"' --inactive-dim=0.25 -b &    # dim every inactive window except urxvt (handled by .Xresources)
setxkbmap -option caps:escape               # map Esc -> CAPSLOCK
export _JAVA_AWT_WM_NONREPARENTING=1        # fix jabref for tiling WM

xmonad                                      # and go...
