#!/bin/bash


function init_rpc {
	echo "Starting rpcbind"
	rpcbind || return 0
	rpc.statd -L || return 0
	rpc.idmapd || return 0
	sleep 1
}

function init_dbus {
	echo "Starting dbus"
	#rm -f /var/run/dbus/system_bus_socket
	rm -f /var/run/messagebus.pid
	dbus-uuidgen --ensure
	dbus-daemon --system --fork
	sleep 1
}


init_rpc
init_dbus

echo "Starting Ganesha NFS"

exec /usr/bin/ganesha.nfsd -F -L /dev/stdout -N NIV_EVENT
