#!/bin/bash
set -x
source .env

# 1. Descargar y descomprimir WordPress en /tmp
wget https://wordpress.org/latest.tar.gz -P /tmp
tar -xzvf /tmp/latest.tar.gz -C /tmp

# 2. Limpiar /var/www/html y mover archivos de WordPress
rm -f /var/www/html/index.html
mv -f /tmp/wordpress/* /var/www/html/

# 3. Crear Base de Datos y usuario en MariaDB
mariadb -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME;"
mariadb -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME;"
mariadb -u root <<< "DROP USER IF EXISTS '$WORDPRESS_DB_USER'@'$IP_CLIENTE_MYSQL';"
mariadb -u root <<< "CREATE USER '$WORDPRESS_DB_USER'@'$IP_CLIENTE_MYSQL' IDENTIFIED BY '$WORDPRESS_DB_PASSWORD';"
mariadb -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO '$WORDPRESS_DB_USER'@'$IP_CLIENTE_MYSQL';"
mariadb -u root <<< "FLUSH PRIVILEGES;"

# 4. Configurar wp-config.php desde el archivo de ejemplo
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

sed -i "s/database_name_here/$WORDPRESS_DB_NAME/" /var/www/html/wp-config.php
sed -i "s/username_here/$WORDPRESS_DB_USER/" /var/www/html/wp-config.php
sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/" /var/www/html/wp-config.php
sed -i "s/localhost/$WORDPRESS_DB_HOST/" /var/www/html/wp-config.php

# 5. Aplicar permisos al directorio web
chown -R www-data:www-data /var/www/html/

# 6. Crear archivo .htaccess para enlaces permanentes
cat <<EOT > /var/www/html/.htaccess
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
EOT

# Guardar copia en el directorio htaccess para la entrega
cp /var/www/html/.htaccess ~/practica/htaccess/

# 7. Activar modulo mod_rewrite y reiniciar Apache
a2enmod rewrite
systemctl restart apache2
