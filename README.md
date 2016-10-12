# 12c-rac-docker
Multiple node Oracle RAC cluster running in Docker containers
# How to use
It is important when creating the BIND and DHCPD containers that the BIND container is created first. The reason is that there is a key created as part of the BIND image build that DHCPD will use for dynamic dns updates and the key needs to exist when the DHCPD container is created.


# Pipework
The RAC containers use a script called pipework to connect the custom docker networks to the containers. Because the pipework script is working with network namespaces, it must be run as root.
```
sudo mkdir -p /srv/docker/pipework

sudo curl -L -o /srv/docker/pipework/#1 https://raw.githubusercontent.com/jpetazzo/pipework/master/{pipework}

sudo chmod 744 /srv/docker/pipework/pipework
```


# Networks

The BIND, DHCPD, and RAC containers communicate over a 10.10.10.0/24 network. This is known within the cluster as the public network.
```
docker network create --subnet=10.10.10.0/24 pub
```

The 11.11.11.0/24 network is known within the cluster as the private network. This will be used as the cluster interconnect. DHCPD will also serve IP addresses on this network.
```
docker network create --subnet=11.11.11.0/24 pub
```


# BIND
The BIND container will be used for DNS for the cluster.

Create the BIND image.
```
docker build --tag bind Dockerfile-bind
```

Create the BIND container but don't start it until the following step is complete. Unless you need it, leave the web administrator disabled. The `-4` option prevents named from listening on the IPV6 addresses.
```
docker create
--interactive \
--tty \
--name bind \
--hostname bind \
--publish 53:53/tcp \
--publish 53:53/udp \
--volume /srv/docker/bind:/data \
--env WEBMIN_ENABLED=false \
bind \
-4
```

Now connect the 10.10.10.0/24 network to the BIND container.
```
docker network connect --ip 10.10.10.10 pub bind
```

Start the BIND container.
```
docker start bind
```


# DHCPD
The DHCPD container will be used for generating IP addresses need by the cluster nodes.

Create the configuration directory.
```
mkdir -p /srv/docker/dhcpd
```

Copy the dhcpd.conf file to the configuration directory.
```
cp dhcpd.conf /srv/docker/dhcpd/
```

Create the DHCPD container but don't start it until the following step is complete.
```
docker create \
--interactive \
--tty \
--name dhcpd \
--hostname dhcpd \
--volume /srv/docker/dhcpd:/data \
--volume /srv/docker/bind/bind/etc:/keys \
--dns 10.10.10.10 \
networkboot/dhcpd
```

Connect the pub and priv docker networks to the DHCPD container.
```
docker network connect --ip 10.10.10.11 pub dhcpd 

docker network connect --ip 11.11.11.11 priv dhcpd 
```

Start the DHCPD container.
```
docker start dhcpd
```
