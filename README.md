# 12c-rac-docker
Multiple node Oracle RAC cluster running in Docker containers
# How to use
It is important when creating the BIND and DHCPD containers that the BIND container is created first. The reason is that there is a key created as part of the BIND image build that DHCPD will use for dynamic dns updates and the key needs to exist when the DHCPD container is created.

Create the BIND image.
```
docker build --tag bind Dockerfile-bind
```

Create the BIND container but don't start it until the following step is complete. Unless you need it, leave the web administrator disabled. The `-4` option prevents named from listening on the IPV6 addresses.
```
docker create
--interactive true \
--tty true \
--name bind \
--hostname bind \
--publish 53:53/tcp \
--publish 53:53/udp \
--volume /srv/docker/bind:/data \
--env WEBMIN_ENABLED=false \
bind \
-4
```

The BIND, DHCPD, and RAC containers communicate over a 10.10.10.0/24 network. It is important that this network is attached to the BIND container before it is started so that named starts listening on it when the process starts.
```
docker network create --subnet=10.10.10.0/24 pub
```

Now connect the 10.10.10.0/24 network to the BIND container.
```
docker network connect --ip 10.10.10.10 pub bind
```

Start the BIND container.
```
docker start bind
```
