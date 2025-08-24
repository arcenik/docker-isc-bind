################################################################################
FROM debian:trixie
LABEL org.opencontainers.image.authors="github@arcenik.net"
LABEL org.opencontainers.image.source="https://github.com/arcenik/docker-isc-bind"

################################################################################
RUN \
  set -xe ;\
  echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/norec ;\
  echo 'APT::Install-Suggests "false";' > /etc/apt/apt.conf.d/nosug ;\
  apt update ;\
  DEBIAN_FRONTEND=noninteractive apt install -yqq -o=Dpkg::Use-Pty=0 \
    wget curl dh-exec libkrb5-dev libssl-dev libtool bison libdb-dev libldap2-dev \
    libxml2-dev libcap2-dev libgeoip-dev dpkg-dev autotools-dev \
    dh-autoreconf gpg gpg-agent python3-ply pkg-config libuv1-dev libnghttp2-dev \
    libjemalloc-dev

# EOL Q2/2028
ENV BIND_VERSION  '9.18.39'
ENV BIND_FILE     "bind-${BIND_VERSION}.tar.xz"
ENV BIND_ASC_FILE "bind-${BIND_VERSION}.tar.xz.asc"
ENV BIND_URL      'https://ftp.isc.org/isc/bind9/'
ENV ISC_KEY_FILE  'isc-keyblock.asc'

COPY ${ISC_KEY_FILE} /tmp
WORKDIR /tmp
RUN \
  set -xe ;\
  dpkg -l | grep gpg ;\
  gpg --import ${ISC_KEY_FILE} ;\
  curl -vsk "${BIND_URL}${BIND_VERSION}/${BIND_FILE}" -o ${BIND_FILE} ;\
  curl -vsk "${BIND_URL}${BIND_VERSION}/${BIND_ASC_FILE}" -o ${BIND_ASC_FILE} ;\
  gpg --verify ${BIND_ASC_FILE} ${BIND_FILE}

WORKDIR /usr/src
RUN \
  set -xe ;\
  tar xfJ /tmp/${BIND_FILE} ;\
  ln -vs bind-9* bind-9-current ;\
  cd bind-9-current ;\
  ./configure \
      --enable-full-report \
      --prefix=/opt/bind9/ ;\
  make && make install

################################################################################
FROM debian:trixie-slim

RUN \
  set -xe ;\
  echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/norec ;\
  echo 'APT::Install-Suggests "false";' > /etc/apt/apt.conf.d/nosug ;\
  apt update ;\
  DEBIAN_FRONTEND=noninteractive apt dist-upgrade -yqq -o=Dpkg::Use-Pty=0 ;\
  DEBIAN_FRONTEND=noninteractive apt install -yqq -o=Dpkg::Use-Pty=0 openssl libxml2 libuv1 libcap2 \
    libnghttp2-14 libgssapi-krb5-2 libjemalloc2

COPY --from=0 /opt/bind9 /opt/bind9

RUN mkdir /var/cache/bind

VOLUME /etc/bind
EXPOSE 53/udp 53

################################################################################
HEALTHCHECK --interval=30s --timeout=1s \
  CMD /opt/bind9/bin/dig @localhost google.com +short

################################################################################
CMD ["/opt/bind9/sbin/named", "-f", "-c", "/etc/bind/named.conf", "-4"]
