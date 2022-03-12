FROM cometvisu/cometvisuabstractbase:latest

RUN apt-get -qq update \
 && apt-get install -y git openssh-server gnupg \
 && curl -sL https://deb.nodesource.com/setup_12.x | bash - \
 && apt-get install -y nodejs \
 && apt-get remove gnupg \
 && apt-get install -y tcpdump \
 && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* \
 && mkdir /var/run/sshd \
 && echo 'root:cometvisu' | chpasswd \
 && sed -i 's/#*\s*PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config \
 && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
 && mkdir /etc/ssh/root.ssh \
 && ln -s /etc/ssh/root.ssh/ /root/.ssh
EXPOSE 22
# Keep SSH server information over restarts e.g. to prevent changing fingerprints
VOLUME /etc/ssh

COPY develop-entrypoint /usr/local/bin/develop-entrypoint
ENTRYPOINT ["develop-entrypoint"]

# Options - especially for development.
# DO NOT USE for running a real server!
RUN pecl install xdebug \
 && docker-php-ext-enable xdebug \
 && { \
    echo 'xdebug.mode=debug'; \
    echo 'xdebug.discover_client_host=1'; \
    echo 'xdebug.client_port=9003'; \
    echo 'display_errors=Off'; \
    echo 'log_errors=On'; \
    echo 'error_log=/dev/stderr'; \
    echo 'file_uploads=On'; \
    } | tee "/usr/local/etc/php/php.ini"
EXPOSE 9003
# Make life more easy on the shell in the container
RUN { \
    echo "export LS_OPTIONS='--color=auto'"; \
    echo "eval \"\`dircolors -b\`\""; \
    echo "alias ls='ls \$LS_OPTIONS'"; \
    echo "alias ll='ls \$LS_OPTIONS -l'"; \
    echo "alias l='ls \$LS_OPTIONS -lA'"; \
    } | tee -a "/root/.bashrc"

LABEL org.label-schema.build-date="none"
LABEL org.label-schema.description="The CometVisu open source building automation visualization - development container"
LABEL org.label-schema.vcs-url="https://github.com/CometVisu/CometVisu"
LABEL org.label-schema.vcs-ref="devel"
LABEL org.label-schema.version="devel"

# All development files (including the config) will stay within /var/www/html
# so that one has to be a volume - or the source files might get lost
VOLUME /var/www/html

