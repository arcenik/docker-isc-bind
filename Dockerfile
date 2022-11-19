################################################################################
FROM debian:bullseye
MAINTAINER Francois Scala "github@arcenik.net"

################################################################################
RUN \
  apt update &&\
  DEBIAN_FRONTEND=noninteractive apt install -yq \
    wget dh-exec libkrb5-dev libssl-dev libtool bison libdb-dev libldap2-dev \
    libxml2-dev libcap2-dev libgeoip-dev dpkg-dev autotools-dev \
    dh-autoreconf gpg python-ply pkg-config libuv1-dev libnghttp2-dev

ENV BIND_VERSION     "9.18.9"
ENV BIND_FILE        "bind-${BIND_VERSION}.tar.xz"
ENV BIND_SHA512_FILE "bind-${BIND_VERSION}.tar.xz.sha512.asc"
ENV BIND_URL         "https://ftp.isc.org/isc/bind9/"
ENV ISC_KEY_FILE     "isc-2021-2022.asc"

COPY ${ISC_KEY_FILE} /tmp
WORKDIR /tmp
RUN \
  set -xe &&\
  gpg --import ${ISC_KEY_FILE} &&\
  wget "${BIND_URL}${BIND_VERSION}/${BIND_FILE}" -O ${BIND_FILE} &&\
  wget "${BIND_URL}${BIND_VERSION}/${BIND_SHA512_FILE}" -O ${BIND_SHA512_FILE} &&\
  gpg --verify ${BIND_SHA512_FILE} ${BIND_FILE}

WORKDIR /usr/src
RUN \
  set -xe &&\
  tar xfJ /tmp/${BIND_FILE} &&\
  ln -vs bind-9* bind-9-current &&\
  cd bind-9-current &&\
  ./configure \
      --enable-full-report \
      --prefix=/opt/bind9/ &&\
  make && make install

################################################################################
FROM debian:bullseye-slim

RUN \
  set -xe &&\
  apt update &&\
  DEBIAN_FRONTEND=noninteractive apt dist-upgrade -yq &&\
  DEBIAN_FRONTEND=noninteractive apt install -yq openssl libxml2 libuv1 libcap2 \
    libnghttp2-14

COPY --from=0 /opt/bind9 /opt/bind9

RUN mkdir /var/cache/bind

VOLUME /etc/bind
EXPOSE 53/udp 53

################################################################################
CMD ["/opt/bind9/sbin/named", "-f", "-c", "/etc/bind/named.conf", "-4"]
