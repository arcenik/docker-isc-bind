################################################################################
FROM debian:buster
MAINTAINER Francois Scala "github@arcenik.net"

################################################################################
RUN \
  apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -yq \
    wget dh-exec libkrb5-dev libssl-dev libtool bison libdb-dev libldap2-dev \
    libxml2-dev libcap2-dev libgeoip-dev dpkg-dev python3 dh-systemd \
    autotools-dev dh-autoreconf gpg

ENV BIND_VERSION     "9.14.5"
ENV BIND_FILE        "${BIND_VERSION}.tgz"
ENV BIND_SHA512_FILE "${BIND_VERSION}.tgz.sha512.asc"
ENV BIND_URL         "https://ftp.isc.org/isc/bind9/${BIND_VERSION}/bind-${BIND_VERSION}.tar.gz"
ENV BIND_SHA512_URL  "https://ftp.isc.org/isc/bind9/${BIND_VERSION}/bind-${BIND_VERSION}.tar.gz.sha512.asc"
ENV ISC_KEY_FILE     "isc-2019-2020.asc"

COPY ${ISC_KEY_FILE} /tmp
WORKDIR /tmp
RUN \
  set -xe &&\
  gpg --import ${ISC_KEY_FILE} &&\
  wget ${BIND_URL} -O ${BIND_FILE} &&\
  wget ${BIND_SHA512_URL} -O ${BIND_SHA512_FILE} &&\
  gpg --verify ${BIND_SHA512_FILE} ${BIND_FILE}

WORKDIR /usr/src
RUN \
  set -xe &&\
  tar xfz /tmp/${BIND_FILE} &&\
  ln -vs bind-9* bind-9-current &&\
  cd bind-9-current &&\
  ./configure \
      --enable-full-report \
      --prefix=/opt/bind9/ \
      --without-python \
      2>&1 | tee configure.log &&\
  make  2>&1 | tee make.log &&\
  make install  2>&1 | tee make-install.log

################################################################################
FROM francois75/docker-authfromhost:debian-stretch-slim

RUN \
  set -xe &&\
  apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -yq &&\
  DEBIAN_FRONTEND=noninteractive apt-get install -yq openssl

COPY --from=0 /opt/bind9 /opt/bind9
COPY --from=0 /usr/src/bind-9-current/make.log /root/make.log
COPY --from=0 /usr/src/bind-9-current/make-install.log /root/make-install.log

RUN mkdir /var/cache/bind

VOLUME /etc/bind
EXPOSE 53/udp 53

################################################################################
CMD ["/opt/bind9/sbin/named", "-f", "-c", "/etc/bind/named.conf", "-4"]
