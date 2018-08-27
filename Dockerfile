FROM php:7.2-apache
#WORKDIR "/var/www/html/"

# Fix debconf warnings upon build
#ARG DEBIAN_FRONTEND=noninteractive

# Install selected extensions and other stuff
#RUN apt-get update \
#    && apt-get -y --no-install-recommends install  php-xdebug \
#    && apt-get -y install git sshfs \
#    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Overwrite package default - allow index
RUN { \
		echo '<FilesMatch \.php$>'; \
		echo '\tSetHandler application/x-httpd-php'; \
		echo '</FilesMatch>'; \
		echo; \
		echo 'DirectoryIndex enabled'; \
		echo 'DirectoryIndex index.php index.html'; \
		echo; \
		echo '<Directory /var/www/>'; \
		echo '\tOptions +Indexes'; \
		echo '\tAllowOverride All'; \
		echo '</Directory>'; \
	} | tee "$APACHE_CONFDIR/conf-available/cm-docker-php.conf" \
	&& a2disconf docker-php
	&& a2enconf cm-docker-php

RUN pecl install xdebug-2.6.0 \
    && docker-php-ext-enable xdebug

CMD ["apache2-foreground"]