#!/usr/bin/env bash

declare -A params=$6     # Create an associative array
paramsTXT=""
if [ -n "$6" ]; then
   for element in "${!params[@]}"
   do
      paramsTXT="${paramsTXT}
      fastcgi_param ${element} ${params[$element]};"
   done
fi

if [ "$7" = "true" ] && [ "$5" = "7.2" ]
then configureZray=""
else configureZray=""
fi

block="server {
    listen ${3:-80};
    listen ${4:-443} ssl http2;
    server_name .$1;
    root \"$2\";

    index index.php index.html index.htm;

    add_header X-Powered-Host \$hostname;
	fastcgi_hide_header X-Powered-By;

    charset utf-8;

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/$1-error.log error;

    sendfile off;

    client_max_body_size 100m;

    if (!-e \$request_filename) {
		rewrite  ^/(.+?\.php)/?(.*)$  /\$1/\$2  last;
		rewrite  ^/(.*)$  /index.php/\$1  last;
	}

    location ~ \.php($|/){

        fastcgi_split_path_info ^(.+\.php)(/.+)\0$;
        fastcgi_pass unix:/var/run/php/php$5-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        set \$real_script_name \$fastcgi_script_name;
		if (\$real_script_name ~ \"^\(.+?\.php\)\(/.+\)\$\") {
			set \$real_script_name \$1;
		}
		fastcgi_split_path_info ^(.+?\.php)(/.*)$;
		fastcgi_param PATH_INFO    \$fastcgi_path_info;
		fastcgi_param SCRIPT_NAME  \$real_script_name;
        fastcgi_param SCRIPT_FILENAME \$document_root\$real_script_name;
        fastcgi_param PHP_VALUE    open_basedir=\$document_root:/tmp/:/proc/;

        $paramsTXT

        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }

    ssl_certificate     /etc/nginx/ssl/$1.crt;
    ssl_certificate_key /etc/nginx/ssl/$1.key;
}
"

echo "$block" > "/etc/nginx/sites-available/$1"
ln -fs "/etc/nginx/sites-available/$1" "/etc/nginx/sites-enabled/$1"
