FROM cometvisu/cometvisuabstractbase:latest

RUN apt-get -qq update \
 && apt-get install -y git openssh-server gnupg \
 && curl -sL https://deb.nodesource.com/setup_11.x | bash - \
 && apt-get install -y nodejs \
 && apt-get remove gnupg \
 && apt-get install -y --no-install-recommends rrdtool \
 && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* \
 && mkdir /var/run/sshd \
 && echo 'root:cometvisu' | chpasswd \
 && sed -i 's/#*\s*PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
EXPOSE 22

# Options - especially for development.
# DO NOT USE for running a real server!
RUN pecl install xdebug-2.6.0 \
 && docker-php-ext-enable xdebug \
 && { \
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

# TODO: GIT checkout
# git co https://github.com/ChristianMayer/CometVisu.git . (TODO)
# git submodule init
# git submodule update
# cd CometVisu
# npm install
# ./generate.py source

VOLUME /var/www/html/config

