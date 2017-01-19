#!/bin/bash


NSPID=$(/usr/bin/docker inspect --format='{{ .State.Pid }}' rac1)

/usr/bin/rm -rf "/var/run/netns/${NSPID?}"
/usr/bin/mkdir -p "/var/run/netns"
/usr/bin/ln -s "/proc/${NSPID?}/ns/net" "/var/run/netns/${NSPID?}"

BRIDGE=$(/usr/bin/docker network ls -q -f NAME=pub)
/usr/bin/ip link del dev rac1-pub 2>/dev/null
/usr/bin/ip link add name rac1-pub mtu 1500 type veth peer name eth-pub mtu 1500
/usr/bin/sleep 5
/usr/bin/ip link set rac1-pub master br-${BRIDGE?}
/usr/bin/ip link set rac1-pub up
/usr/bin/ip link set eth-pub netns ${NSPID?}
/usr/bin/ip netns exec ${NSPID?} /usr/bin/ip link set eth-pub up

/usr/bin/docker exec rac1 \
/usr/bin/rm -f /etc/systemd/system/dhclient-rac1-eth-pub.service

/usr/bin/docker exec rac1 \
/usr/bin/ln -s \
/usr/lib/custom_services/dhclient-rac1-eth-pub.service \
/etc/systemd/system/dhclient-rac1-eth-pub.service

/usr/bin/docker exec rac1 \
/usr/bin/systemctl stop dhclient-rac1-eth-pub.service

/usr/bin/docker exec rac1 \
/usr/bin/systemctl daemon-reload

/usr/bin/docker exec rac1 \
/usr/bin/systemctl start dhclient-rac1-eth-pub.service

BRIDGE=$(/usr/bin/docker network ls -q -f NAME=priv)
/usr/bin/ip link del dev rac1-priv 2>/dev/null
/usr/bin/ip link add name rac1-priv mtu 1500 type veth peer name eth-priv mtu 1500
/usr/bin/sleep 5
/usr/bin/ip link set rac1-priv master br-${BRIDGE?}
/usr/bin/ip link set rac1-priv up
/usr/bin/ip link set eth-priv netns ${NSPID?}
/usr/bin/ip netns exec ${NSPID?} /usr/bin/ip link set eth-priv up

/usr/bin/docker exec rac1 \
/usr/bin/rm -f /etc/systemd/system/dhclient-rac1-eth-priv.service

/usr/bin/docker exec rac1 \
/usr/bin/ln -s \
/usr/lib/custom_services/dhclient-rac1-eth-priv.service \
/etc/systemd/system/dhclient-rac1-eth-priv.service

/usr/bin/docker exec rac1 \
/usr/bin/systemctl stop dhclient-rac1-eth-priv.service

/usr/bin/docker exec rac1 \
/usr/bin/systemctl daemon-reload

/usr/bin/docker exec rac1 \
/usr/bin/systemctl start dhclient-rac1-eth-priv.service


/usr/bin/rm -rf "/var/run/netns/${NSPID?}"
