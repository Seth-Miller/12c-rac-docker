#!/bin/bash


NSPID=$(docker inspect --format='{{ .State.Pid }}' rac2)
BRIDGE=$(docker network ls -q -f NAME=pub)

rm -rf "/var/run/netns/${NSPID?}"
ln -s "/proc/${NSPID?}/ns/net" "/var/run/netns/${NSPID?}"
ip link del dev rac2-pub 2>/dev/null
ip link add name rac2-pub mtu 1500 type veth peer name eth-pub mtu 1500
ip link set rac2-pub master br-${BRIDGE?}
ip link set rac2-pub up
ip link set eth-pub netns ${NSPID?}
ip netns exec ${NSPID?} ip link set eth-pub up
rm -rf "/var/run/netns/${NSPID?}"
