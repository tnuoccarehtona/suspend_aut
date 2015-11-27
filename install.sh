#!/bin/bash
if [ "$XDG_CURRENT_DESKTOP" != "LXDE" ] && [ `id -u` != 0  ];then
	echo "Warning: suspend code may be different for you window manager. Please edit /etc/default/suspender_aut after the installation !!!"
fi
#Promp sudo password
if [ `id -u` != 0  ];then
	sudo "$0" "$@"
	exit $?
fi
#Check if xautolock exist
if ! which xautolock 2>&1>/dev/null ;then
	echo "xautolock does not exist!!!"
	exit 1
fi
#Check if gnome-screensaver exist
if which gnome-screensaver  2>&1>/dev/null ;then
	echo "installing suspender_aut  config file  for gnome_screensaver"
	cp suspender_aut_gnome_screensaver /etc/default/suspender_aut
elif which i3lock;then
	echo "installing suspender_aut config file for i3lock"
	cp suspender_aut_i3lock /etc/default/suspender_aut
else
	echo "No recommended screenlocker is installed, so that an default configuration is used."
	cp suspender_aut_empty /etc/default/suspender_aut
fi
echo "installing suspender_aut.sh"
cp -f suspender_aut.sh /usr/bin/suspender_aut.sh
chmod 755 /usr/bin/suspender_aut.sh
echo "done!!!"
exit 0
