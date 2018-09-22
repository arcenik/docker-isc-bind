

## Source

https://www.isc.org/downloads/

## Usage

### Run with docker-compose

Here is an example of **docker-compose** file :

```yaml
---
version: '3'
  services:
    bind:
      build: ./bind
      image: bind:fromsrc
      hostname: bind
      deploy:
        resources:
          limits:
            cpus: '0.5'
            memory: 128M
      restart: always
      volumes:
        - "/srv/bind:/etc/bind"
      ports:
        - "192.168.0.10:53:53/udp"
        - "192.168.0.10:53:53"
```

### Persistent volumes

* /etc/bind : Bind configuration and zones
