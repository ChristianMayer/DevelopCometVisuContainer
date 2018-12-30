##############
# Run environment
FROM cometvisu/cometvisuabstractbase:latest

# Get CometVisu release 0.10.2 - and patch it inplace to make the editor work with newer Webkit browsers
RUN export COMETVISU_DOWNLOAD_SHA256=4ba6cb505c2fd1f5d16c50e0bbb5e98b45ea93a4d9ce17202f1ed5ca0c1432b8 \
 && curl -L -o CometVisu.tar.gz https://github.com/CometVisu/CometVisu/releases/download/v0.10.2/CometVisu-0.10.2.tar.gz \
#RUN wget -O CometVisu.tar.gz https://github.com/CometVisu/CometVisu/releases/download/v0.10.2/CometVisu-0.10.2.tar.gz \
 && echo "$COMETVISU_DOWNLOAD_SHA256 CometVisu.tar.gz" | sha256sum -c - \
 && tar xvf CometVisu.tar.gz \
 && sed -i 's/return 1==$.browser.webkit/return e;1==$.browser.webkit/' cometvisu/release/editor/lib/Schema.js \
 && sed -i 's@http://www.reliablecounter@https://www.reliablecounter@' cometvisu/release/demo/visu_config_demo.xml \
 && mv cometvisu/release/* /var/www/html/ \
 && rm -rf CometVisu.tar.gz cometvisu

LABEL org.label-schema.build-date="2017-04-09"
LABEL org.label-schema.description="The CometVisu open source building automation visualization"
LABEL org.label-schema.vcs-url="https://github.com/CometVisu/CometVisu"
LABEL org.label-schema.vcs-ref="v0.10.2"
LABEL org.label-schema.version="0.10.2"

RUN { \
    echo "export LS_OPTIONS='--color=auto'"; \
    echo "eval \"\`dircolors -b\`\""; \
    echo "alias ls='ls \$LS_OPTIONS'"; \
    echo "alias ll='ls \$LS_OPTIONS -l'"; \
    echo "alias l='ls \$LS_OPTIONS -lA'"; \
    } | tee -a "/root/.bashrc"

VOLUME /var/www/html/config

