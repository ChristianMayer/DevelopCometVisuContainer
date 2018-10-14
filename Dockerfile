FROM php:7.2-apache as builder
#WORKDIR "/var/www/html/"

# Fix debconf warnings upon build
#ARG DEBIAN_FRONTEND=noninteractive

# Install selected extensions and other stuff
#RUN apt-get update \
#    && apt-get -y --no-install-recommends install  php-xdebug \
#    && apt-get -y install git sshfs \
#    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

##################
# Compile knxd 0.0.5.1
RUN apt-get -qq update \
 && apt-get install -y python python-dev python-pip python-virtualenv \
 && apt-get install -y build-essential gcc git rsync cmake make g++ binutils automake flex bison patch wget libtool \
 && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

ENV KNXDIR /usr
ENV INSTALLDIR $KNXDIR/local
ENV SOURCEDIR  $KNXDIR/src
ENV LD_LIBRARY_PATH $INSTALLDIR/lib

WORKDIR $SOURCEDIR

# build pthsem
RUN wget -O pthsem_2.0.8.tar.gz "https://osdn.net/frs/g_redir.php?m=kent&f=bcusdk%2Fpthsem%2Fpthsem_2.0.8.tar.gz" \
 && tar -xzf pthsem_2.0.8.tar.gz \
 && cd pthsem-2.0.8 && ./configure --prefix=$INSTALLDIR/ && make && make test && make install

# build linknx
#COPY linknx-0.0.1.32.tar.gz linknx-0.0.1.32.tar.gz
#RUN tar -xzf linknx-0.0.1.32.tar.gz
#RUN cd linknx-0.0.1.32 && ./configure --without-log4cpp --without-lua --prefix=$INSTALLDIR/ --with-pth=$INSTALLDIR/ && make && make install

# build eibd
#RUN wget -O bcusdk_0.0.5.tar.gz "https://de.osdn.net/frs/g_redir.php?m=kent&f=bcusdk%2Fbcusdk%2Fbcusdk_0.0.5.tar.gz"
RUN wget -O knxd_0.0.5.1.tar.gz "https://github.com/knxd/knxd/archive/0.0.5.1.tar.gz" \
 && tar -xzf knxd_0.0.5.1.tar.gz \
 && cd knxd-0.0.5.1 && ./bootstrap.sh \
 && ./configure --enable-onlyeibd --enable-eibnetip --enable-eibnetiptunnel --disable-eibnetipserver \
    --disable-ft12 --disable-pei16 --disable-tpuart --disable-pei16s  --disable-tpuarts --disable-usb --disable-ncn5120 \
    --enable-groupcache --disable-java \
    --disable-shared --enable-static \
    --prefix=$INSTALLDIR/ --with-pth=$INSTALLDIR/ \
 && make && make install
# && cd knxd-0.0.5.1 && ./bootstrap.sh && ./configure --enable-onlyeibd --enable-eibnetiptunnel --enable-eibnetipserver --enable-ft12 --prefix=$INSTALLDIR/ --with-pth=$INSTALLDIR/ && make && make install

#RUN useradd eibd -s /bin/false -U -M
#ADD eibd.sh /etc/init.d/eibd
#RUN chmod +x /etc/init.d/eibd
#RUN update-rc.d eibd defaults 98 02

##############
# Run environment
FROM php:7.2-apache
COPY --from=builder /usr/local/bin/knxd /usr/bin/knxd
COPY --from=builder /usr/local/lib/lib* /usr/lib/
COPY --from=builder /usr/src/knxd-0.0.5.1/src/examples/busmonitor1 /usr/src/knxd-0.0.5.1/src/examples/vbusmonitor1 /usr/src/knxd-0.0.5.1/src/examples/vbusmonitor1time /usr/src/knxd-0.0.5.1/src/examples/vbusmonitor2 /usr/src/knxd-0.0.5.1/src/examples/groupswrite /usr/src/knxd-0.0.5.1/src/examples/groupwrite /usr/src/knxd-0.0.5.1/src/examples/groupread /usr/src/knxd-0.0.5.1/src/examples/groupreadresponse /usr/src/knxd-0.0.5.1/src/examples/groupcacheread /usr/src/knxd-0.0.5.1/src/examples/groupsocketread /usr/local/bin/
COPY --from=builder /usr/src/knxd-0.0.5.1/src/examples/eibread-cgi /usr/lib/cgi-bin/r
COPY --from=builder /usr/src/knxd-0.0.5.1/src/examples/eibwrite-cgi /usr/lib/cgi-bin/w

#RUN /usr/src/bcusdk-0.0.5/eibd/server/eibd -e 1.2.3 -c -u -d ipt:192.168.0.30
#RUN /usr/local/bin/knxd -d -e 1.1.239 -c -u ipt:192.168.0.30
# knxd -u -i ipt:192.168.0.30:3671 -d/var/log/eibd.log -e 1.1.239 -c -t1023
#knxd -u -i iptn:192.168.0.30:3671 -d/var/log/eibd.log -e 1.1.239 -c -t1023 -f9
##RUN /usr/local/bin/knxd -u -i iptn:192.168.0.30:3671 -d/var/log/eibd.log -e 1.1.239 -c

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
	&& a2enconf cm-docker-php \
	&& { \
	    echo "#!/bin/sh"; \
        echo "echo Content-Type: text/plain"; \
        echo "echo"; \
        echo 'echo "{ \"v\":\"0.0.1\", \"s\":\"SESSION\" }"'; \
        } | tee "/usr/lib/cgi-bin/l" \
    && chmod +x /usr/lib/cgi-bin/l \
	#& ln -s /usr/src/knxd-0.0.5.1/src/examples/eibread-cgi /usr/lib/cgi-bin/r \
	#& ln -s /usr/src/knxd-0.0.5.1/src/examples/eibwrite-cgi /usr/lib/cgi-bin/w \
	&& a2enmod cgi

RUN wget -O CometVisu.tar.gz https://github.com/CometVisu/CometVisu/releases/download/v0.10.2/CometVisu-0.10.2.tar.gz \
 && tar xvf CometVisu.tar.gz \
 && mv cometvisu/release/* /var/www/html/ \
 && rm -rf cometvisu CometVisu.tar.gz

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

#CMD ["apache2-foreground"]
CMD knxd -u -i iptn:192.168.0.30:3671 -d/var/log/eibd.log -e 1.1.239 -c && chmod a+w /tmp/eib && apache2-foreground