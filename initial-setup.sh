#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root or with 'sudo ./initial-setup.sh'"
  exit
fi

read -r -p "Upgrade and update? [Y/n]" response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
	echo 'updating & upgrading';
	sudo apt update && sudo apt upgrade -y
else
	echo 'omiting';
fi

read -r -p "Install last version of MariaDB or last version on MySQL? [mariadb/mysql]" database
if [[ "$database" == "mariadb" ]]; then
	echo -e '\ninstalling MariadDB\n'
	sudo apt install mariadb-client mariadb-server -y
else
	echo -e '\Ininstalling MySQL\n'
	sudo apt-get install mysql-server mysql-client -y 
fi

read -r -p "Run secure installation script? [Y/n]" response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
	sudo mysql_secure_installation
fi

echo -e '\nCreating user "admin"@"%" identified by "tmercer"\n'
sudo mariadb -e "CREATE USER 'admin'@'%' IDENTIFIED BY 'tmercer';"
sudo mariadb -e "GRANT ALL PRIVILEGES on *.* to 'admin'@'%';"
sudo mariadb -e 'FLUSH PRIVILEGES;'

echo -e '\nUpdate mariadb conf file to allow remote conections, modify bind-address = *\n(Not implemented for MySQL).\n'
read -n 1 -s -r -p "Press any key to continue"
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf

echo -e '\nInstalling last versionf of PHP from repositories & php importatnt packages for ZEN\n'
sudo apt install php -y
sudo apt install php libapache2-mod-php php-common php-mbstring php-xmlrpc php-soap php-gd php-xml php-intl php-mysql php-cli php-ldap php-zip php-curl -y

sudo apt-get install -y software-properties-common
sudo add-apt-repository ppa:ondrej/php

sudo apt-get install php5.6 -y

echo -e '\nSelect php version\n'
read -n 1 -s -r -p "Press any key to continue"
sudo update-alternatives --config php

# echo -e '\nCHANGE NETPLAN DEAFULT IP\n'
# NETPLAN_FILES=$(ls /etc/netplan/)
# echo ${NETPLAN_FILES}
# echo -e 'sudo nano /etc/netplan/...'
# ls -al /etc/netplan/

##### permitir al usuario ejecutar comando sudo nano /etcnetplan/50-

# read -r -p "Mount service to automount {docs, html, weblibs} folders? [Y/n]" response
# if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
# 	echo -e "Creating directories\n"
# 	mkdir /home/${USER}
# else
# 	echo 'omiting';
# fi

#path vars
CONFIG_PATH=/etc/apache2/sites-available/
EXTENSION=".conf"

read -r -p "Install apache2? [Y/n]" response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
	sudo apt install apache2 -y
	read -r -p "Enable rewriteEngine? [Y/n]" response
	if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
		sudo a2enmod rewrite
	fi
	read -r -p "Create virtualhost? [Y/n]" response
	if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
		read -r -p "File name(no extension)? [name]" NAME
		read -r -p "Default port? [port]" PORT
		read -r -p "Document root? [path]" document_root
		read -r -p "ServerName & ServerAlias? [domain.local]" DOMAIN

		echo -e '<VirtualHost *:'${PORT}'>' >> ${CONFIG_PATH}${NAME}${EXTENSION}
		echo -e '\tDocumentRoot '${document_root}'\n' >> ${CONFIG_PATH}${NAME}${EXTENSION}
		echo -e '\tServerName '${DOMAIN} >> ${CONFIG_PATH}${NAME}${EXTENSION}
		echo -e '\tServerAlias '${DOMAIN}'\n' >> ${CONFIG_PATH}${NAME}${EXTENSION}
        echo -e '\tErrorLog ${APACHE_LOG_DIR}/'${NAME}'_error.log' >> ${CONFIG_PATH}${NAME}${EXTENSION}
        echo -e '\tCustomLog ${APACHE_LOG_DIR}/'${NAME}'_access.log combined\n' >> ${CONFIG_PATH}${NAME}${EXTENSION}
		echo -e '\t<Directory "'${document_root}'">' >> ${CONFIG_PATH}${NAME}${EXTENSION}
		echo -e '\t\tAllowOverride All' >> ${CONFIG_PATH}${NAME}${EXTENSION}
		echo -e '\t\tOptions +Indexes' >> ${CONFIG_PATH}${NAME}${EXTENSION}
		echo -e '\t\tRequire all granted' >> ${CONFIG_PATH}${NAME}${EXTENSION}
		echo -e '\t</Directory>' >> ${CONFIG_PATH}${NAME}${EXTENSION}
		echo -e '</VirtualHost>' >> ${CONFIG_PATH}${NAME}${EXTENSION}
        read -r -p "Enable ${NAME}${EXTENSION}? [Y/n]" response
	    if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
		    sudo a2ensite ${NAME}${EXTENSION}
	    fi
        read -r -p "Modify apache.conf to AllowOverride (All) ? [Y/n]" response
	    if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
		    sudo nano /etc/apache2/apache2.conf
	    fi
	fi
fi

# read -r -p "Install npm? [Y/n]" response
# if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
# 	sudo apt install npm -y
# 	read -r -p "Install bootstrap? [Y/n]" response
# 	if[[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
# 	then
# 		npm install popper
# 		npm install popper.js@^1.14.7
# 		npm install jquery
# 		npm install bootstrap
# 	fi
# else
# 	echo -e '\nOmiting npm\n';
# fi

# read -r -p "Install composer? [Y/n]" response
# if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
# 	sudo apt install composer -y
# 	read -r -p "install zendframework? [Y/n]" response
# 	if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
# 		composer require zendframework/zendframework
# 	fi
# fi

read -r -p "Restrat services? [Y/n]" response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
	sudo systemctl restart apache2
	if [[ "$database" == "mariadb" ]]; then
		sudo systemctl restart mariadb.service
	else
		sudo systemctl restart mysql.service
	fi
fi

echo -e "Script done, test conection with admin:tmercer"
read -n 1 -s -r -p "press any key to continue"
echo -e "\n"

