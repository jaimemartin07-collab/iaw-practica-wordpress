#!/bin/bash
set -x

# Actualizar repositorios e instalar Apache y MariaDB
sudo apt update
sudo apt install apache2 mariadb-server php libapache2-mod-php php-mysql -y

# Reiniciar servicio de Apache
sudo systemctl restart apache2
