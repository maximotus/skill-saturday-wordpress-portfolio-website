USERID=$1
USERNAME=$2
PORT=$3
MYSQL_PASS=$4

echo "Creating DB user $USERNAME"
sudo mysql -u root -p$MYSQL_PASS -e "CREATE DATABASE $USERNAME;"
sudo mysql -u root -p$MYSQL_PASS -e "CREATE USER '$USERNAME'@'localhost' IDENTIFIED BY '$USERNAME';"
sudo mysql -u root -p$MYSQL_PASS -e "GRANT ALL ON $USERNAME.* TO '$USERNAME'@'localhost' WITH GRANT OPTION;"
sudo mysql -u root -p$MYSQL_PASS -e "FLUSH PRIVILEGES;"

echo "Copying Wordpress..."
sudo cp -r /tmp/wordpress/ /var/www/wordpress$USERID
sudo chown -R www-data:www-data /var/www/wordpress$USERID/
sudo chmod -R 755 /var/www/wordpress$USERID/

echo "Setting up nginx site..."
sudo cat << EOF > /etc/nginx/sites-available/wordpress$USERID.conf
server {
    listen $PORT;
    listen [::]:$PORT;
    root /var/www/wordpress$USERID;
    index  index.php index.html index.htm;
    server_name  example.com www.example.com;

    client_max_body_size 100M;
    autoindex off;
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
         include snippets/fastcgi-php.conf;
         fastcgi_pass unix:/var/run/php/php8.0-fpm.sock;
         fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
         include fastcgi_params;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/wordpress$USERID.conf /etc/nginx/sites-enabled/

echo "Restarting nginx..."
sudo service nginx restart

echo "Done!"