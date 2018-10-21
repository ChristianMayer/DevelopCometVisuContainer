FROM php:7.2-apache as builder

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

# build knxd
RUN wget -O knxd_0.0.5.1.tar.gz "https://github.com/knxd/knxd/archive/0.0.5.1.tar.gz" \
 && tar -xzf knxd_0.0.5.1.tar.gz \
 && cd knxd-0.0.5.1 && ./bootstrap.sh \
 && ./configure --enable-onlyeibd --enable-eibnetip --enable-eibnetiptunnel --disable-eibnetipserver \
    --disable-ft12 --disable-pei16 --disable-tpuart --disable-pei16s  --disable-tpuarts --disable-usb --disable-ncn5120 \
    --enable-groupcache --disable-java \
    --disable-shared --enable-static \
    --prefix=$INSTALLDIR/ --with-pth=$INSTALLDIR/ \
 && make && make install

# Get CometVisu release 0.10.2 - and patch it inplace to make the editor work with newer Webkit browsers
RUN wget -O CometVisu.tar.gz https://github.com/CometVisu/CometVisu/releases/download/v0.10.2/CometVisu-0.10.2.tar.gz \
 && tar xvf CometVisu.tar.gz \
 && sed -i 's/return 1==$.browser.webkit/return e;1==$.browser.webkit/' editor/lib/Schema.js

##############
# Run environment
FROM php:7.2-apache

LABEL maintainer="http://www.cometvisu.org/" \
      org.cometvisu.version="0.10.2" \
      org.cometvisu.knxd.version="0.0.5.1"

COPY --from=builder /usr/local/bin/knxd /usr/bin/knxd
COPY --from=builder /usr/local/lib/libpthsem.so.20 /usr/lib/
COPY --from=builder /usr/src/knxd-0.0.5.1/src/examples/busmonitor1 /usr/src/knxd-0.0.5.1/src/examples/vbusmonitor1 /usr/src/knxd-0.0.5.1/src/examples/vbusmonitor1time /usr/src/knxd-0.0.5.1/src/examples/vbusmonitor2 /usr/src/knxd-0.0.5.1/src/examples/groupswrite /usr/src/knxd-0.0.5.1/src/examples/groupwrite /usr/src/knxd-0.0.5.1/src/examples/groupread /usr/src/knxd-0.0.5.1/src/examples/groupreadresponse /usr/src/knxd-0.0.5.1/src/examples/groupcacheread /usr/src/knxd-0.0.5.1/src/examples/groupsocketread /usr/local/bin/
COPY --from=builder /usr/src/knxd-0.0.5.1/src/examples/eibread-cgi /usr/lib/cgi-bin/r
COPY --from=builder /usr/src/knxd-0.0.5.1/src/examples/eibwrite-cgi /usr/lib/cgi-bin/w

## The knxd port:
#EXPOSE 6720
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
#    echo 'echo "{ \"v\":\"0.0.1\", \"s\":\"SESSION\", \"c\": {\"baseURL\": \"/proxy/cgi-bin/\"} }"'; \
    } | tee "/usr/lib/cgi-bin/l" \
 && chmod +x /usr/lib/cgi-bin/l \
 && a2enmod cgi \
 && a2enmod headers

COPY --from=builder /usr/src/cometvisu/release/ /var/www/html/

# Options - especially for development.
# DO NOT USE for running a real server!
#RUN pecl install xdebug-2.6.0 \
# && docker-php-ext-enable xdebug \
# && { \
#    echo 'xdebug.remote_enable=1'; \
#    echo 'xdebug.remote_connect_back=1'; \
#    echo 'xdebug.remote_port=9000'; \
#    echo 'display_errors=Off'; \
#    echo 'log_errors=On'; \
#    echo 'error_log=/dev/stderr'; \
#    echo 'file_uploads=On'; \
#    } | tee "/usr/local/etc/php/php.ini"
RUN { \
    echo "export LS_OPTIONS='--color=auto'"; \
    echo "eval \"`dircolors`\""; \
    echo "alias ls='ls \$LS_OPTIONS'"; \
    echo "alias ll='ls \$LS_OPTIONS -l'"; \
    echo "alias l='ls \$LS_OPTIONS -lA'"; \
    } | tee -a "/root/.bashrc"

#RUN { \
#    echo "#!/bin/sh"; \
#    echo "set -e"; \
#    #echo "knxd -u -i iptn:172.17.0.1:3700 -d/var/log/eibd.log -e 1.1.238 -c"; \
#    echo "knxd -i \$KNX_INTERFACE -e \$KNX_PA \$KNXD_PARAMETERS"; \
#    echo "chmod a+w /tmp/eib"; \
#    echo "apache2-foreground"; \
#    echo "if [ \"\${1#-}\" != \"$1\" ]; then"; \
#    echo "    set -- apache2-foreground \"\$@\""; \
#    echo "fi"; \
#    echo "exec \"\$@\""; \
#    } | tee -a "/usr/local/bin/cometvisu-entrypoint" && chmod +x /usr/local/bin/cometvisu-entrypoint
COPY cometvisu-entrypoint /usr/local/bin/cometvisu-entrypoint
ENTRYPOINT ["cometvisu-entrypoint"]

VOLUME /var/www/html/config

ENV KNX_INTERFACE iptn:172.17.0.1:3700
ENV KNX_PA 1.1.238
ENV KNXD_PARAMETERS -u -d/var/log/eibd.log -c

ENV CGI_PATH /cgi-bin/

# TODO:
# HEALTHCHECK

CMD ["apache2-foreground"]
