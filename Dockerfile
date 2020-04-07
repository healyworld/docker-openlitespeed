FROM extremeshok/baseimage-ubuntu AS BUILD
LABEL mantainer="Adrian Kriel <admin@extremeshok.com>" vendor="eXtremeSHOK.com"

USER root

RUN echo "**** Install packages ****" \
  && apt-install gnupg gnupg-utils netcat less

RUN  echo "**** Add OpenLiteSpeed Repo ****" \
  && wget https://rpms.litespeedtech.com/debian/lst_repo.gpg -O /usr/local/src/lst_repo.gpg \
  && apt-key add /usr/local/src/lst_repo.gpg \
  && CODENAME=$(grep 'VERSION_CODENAME=' /etc/os-release | cut -d"=" -f2 | xargs) \
  && echo "deb http://rpms.litespeedtech.com/debian/ ${CODENAME} main" >> /etc/apt/sources.list

RUN echo "**** Install OpenLiteSpeed  ****" \
  && apt-install openlitespeed ols-modsecurity ols-pagespeed

# BUG: lsphp73 is marked as a dependancy.. we will ignore this... a bug has been filed : https://github.com/litespeedtech/openlitespeed/issues/170

RUN echo "**** configure ****"
COPY rootfs/ /

# Update ca-certificates
RUN echo "**** Update ca-certificates ****" \
  && update-ca-certificates

RUN echo "*** house keeping ***" \
  && DEBIAN_FRONTEND=noninteractive \
  && apt-get -y autoremove \
  && apt-get -y autoclean \
  && rm -rf /tmp/* \
  && rm -rf /var/lib/apt/lists/*

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN echo "**** Fix permissions ****" \
  && mkdir -p /var/www/vhosts/localhost/{html,logs,certs} \
  && chown -R nobody:nogroup /var/www/vhosts/

COPY rootfs/ /

WORKDIR /var/www/vhosts/localhost/

EXPOSE 80 443 443/udp 7080

# "when the SIGTERM signal is sent, it immediately quits and all established connections are closed"
# "graceful stop is triggered when the SIGUSR1 signal is sent "
STOPSIGNAL SIGUSR1

HEALTHCHECK --interval=5s --timeout=5s CMD [ "301" = "$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:7080/)" ] || exit 1

ENTRYPOINT ["/init"]