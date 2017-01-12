#!/bin/bash


NSPID=$(docker inspect --format='{{ .State.Pid }}' rac1)
BRIDGE=$(docker network ls -q -f NAME=priv)

rm -rf "/var/run/netns/${NSPID?}"
ln -s "/proc/${NSPID?}/ns/net" "/var/run/netns/${NSPID?}"
ip link del dev rac1-priv 2>/dev/null
ip link add name rac1-priv mtu 1500 type veth peer name eth-priv mtu 1500
ip link set rac1-priv master br-${BRIDGE?}
ip link set rac1-priv up
ip link set eth-priv netns ${NSPID?}
ip netns exec ${NSPID?} ip link set eth-priv up
rm -rf "/var/run/netns/${NSPID?}"
