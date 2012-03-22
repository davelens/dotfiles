#!/bin/bash

project=$1
docroot=$2

if [[ $project == "" ]] || [[ $docroot == "" ]] || [[ `whoami` != 'root' ]];
then
	echo "usage: sudo ./add_vhost.sh <project> <document_root>"
else
	# Apache uses /etc/apache2/sites-enabled as vhost folder, Mac uses /etc/apache2/other
	if [[ `uname -s` == 'Darwin' ]];
	then
		vhost_folder='other'
	else
		vhost_folder='sites-enabled'
	fi


	# create a separate .conf file for this vhost
	echo -e "<VirtualHost *:80>\n\tServerName $project.dev\n\tDocumentRoot $docroot\n\n\t<Directory $docroot>\n\t\tOptions Includes FollowSymLinks\n\t\tAllowOverride All\n\t\tOrder allow,deny\n\t\tAllow from all\n\t</Directory>\n</VirtualHost>" >> /etc/apache2/$vhost_folder/$project.conf

	# append the TLD to the hosts file
	echo -e "127.0.0.1 $project.dev" >> /etc/hosts

	# restart apache
	apachectl restart
fi

