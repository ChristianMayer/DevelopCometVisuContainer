FROM php:7.2-apache
#WORKDIR "/var/www/html/"

# Fix debconf warnings upon build
#ARG DEBIAN_FRONTEND=noninteractive

# Install selected extensions and other stuff
#RUN apt-get update \
#    && apt-get -y --no-install-recommends install  php-xdebug \
#    && apt-get -y install git sshfs \
#    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

##################
# Compile eibd 0.0.5
RUN apt-get -qq update
RUN apt-get install -y python python-dev python-pip python-virtualenv
RUN apt-get install -y build-essential gcc git rsync cmake make g++ binutils automake flex bison patch wget libtool

ENV KNXDIR /usr
ENV INSTALLDIR $KNXDIR/local
ENV SOURCEDIR  $KNXDIR/src
ENV LD_LIBRARY_PATH $INSTALLDIR/lib

WORKDIR $SOURCEDIR

# build pthsem
RUN wget -O pthsem_2.0.8.tar.gz "https://osdn.net/frs/g_redir.php?m=kent&f=bcusdk%2Fpthsem%2Fpthsem_2.0.8.tar.gz"
RUN tar -xzf pthsem_2.0.8.tar.gz
RUN cd pthsem-2.0.8 && ./configure --prefix=$INSTALLDIR/ && make && make test && make install

# build linknx
#COPY linknx-0.0.1.32.tar.gz linknx-0.0.1.32.tar.gz
#RUN tar -xzf linknx-0.0.1.32.tar.gz
#RUN cd linknx-0.0.1.32 && ./configure --without-log4cpp --without-lua --prefix=$INSTALLDIR/ --with-pth=$INSTALLDIR/ && make && make install

# build eibd
#RUN wget -O bcusdk_0.0.5.tar.gz "https://de.osdn.net/frs/g_redir.php?m=kent&f=bcusdk%2Fbcusdk%2Fbcusdk_0.0.5.tar.gz"
RUN wget -O knxd_0.0.5.1.tar.gz "https://github.com/knxd/knxd/archive/0.0.5.1.tar.gz"
RUN tar -xzf knxd_0.0.5.1.tar.gz
RUN cd knxd-0.0.5.1 && ./bootstrap.sh && ./configure --enable-onlyeibd --enable-eibnetiptunnel --enable-eibnetipserver --enable-ft12 --prefix=$INSTALLDIR/ --with-pth=$INSTALLDIR/ && make && make install

RUN useradd eibd -s /bin/false -U -M
#ADD eibd.sh /etc/init.d/eibd
#RUN chmod +x /etc/init.d/eibd
#RUN update-rc.d eibd defaults 98 02

#RUN /usr/src/bcusdk-0.0.5/eibd/server/eibd -e 1.2.3 -c -u -d ipt:192.168.0.30

EXPOSE 6720
##################

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
	&& a2disconf docker-php \
	&& a2enconf cm-docker-php

RUN pecl install xdebug-2.6.0 \
    && docker-php-ext-enable xdebug

# Options - especially for development.
# DO NOT USE for running a real server!
RUN { \
        echo 'xdebug.remote_enable=1'; \
        echo 'xdebug.remote_connect_back=1'; \
        echo 'xdebug.remote_port=9000'; \
        echo 'display_errors=Off'; \
        echo 'log_errors=On'; \
        echo 'error_log=/dev/stderr'; \
        echo 'file_uploads=On'; \
    } | tee "/usr/local/etc/php/php.ini"
RUN { \
        echo "export LS_OPTIONS='--color=auto'"; \
        echo "eval \"`dircolors`\""; \
        echo "alias ls='ls \$LS_OPTIONS'"; \
        echo "alias ll='ls \$LS_OPTIONS -l'"; \
        echo "alias l='ls \$LS_OPTIONS -lA'"; \
     } | tee -a "/root/.bashrc"

CMD ["apache2-foreground"]