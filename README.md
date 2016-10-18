# 12c-rac-docker
Multiple node Oracle RAC cluster running in Docker containers.

# How to use
This setup uses block devices for the ASM disks. I would recommend three disks that are at least 4GB each in size.

It is important when creating the BIND and DHCPD containers that the BIND container is created first. The reason is that there is a key created as part of the BIND image build that DHCPD will use for dynamic dns updates and the key needs to exist when the DHCPD container is created.

The passwords for the non-privileged user accounts are all set to `oracle_4U`.


# Pipework
The RAC containers use a script called pipework to connect the custom docker networks to the containers. Because the pipework script is working with network namespaces, it must be run as root.
```
sudo mkdir -p /srv/docker/pipework

sudo curl -L -o /srv/docker/pipework/#1 https://raw.githubusercontent.com/jpetazzo/pipework/master/{pipework}

sudo chmod 744 /srv/docker/pipework/pipework
```


# Oracle installation files
Download the Oracle 12c Grid Infrastructure and Database installation files and unzip them in a directory on the host. The directory will be mounted as a volume in the RAC node containers for installation. The host directory used in this example is `/oracledata/stage`. Once unzipped, there should be a `grid` and `database` folder in `/oracledata/stage`.


# Networks

The BIND, DHCPD, and RAC containers communicate over a 10.10.10.0/24 network. This is known within the cluster as the public network.

Create the public virtual network.
```
docker network create --subnet=10.10.10.0/24 pub
```

The 11.11.11.0/24 network is known within the cluster as the private network. This will be used as the cluster interconnect. DHCPD will also serve IP addresses on this network.

Create the private virtual network.
```
docker network create --subnet=11.11.11.0/24 priv
```


# BIND
The BIND container will be used for DNS for the cluster.

Create the BIND image.
```
docker build --tag bind Dockerfile-bind
```

Create the BIND container but don't start it until the step following this one is complete. Unless you need it, leave the WEBMIN disabled. The `-4` option prevents named from listening on the IPV6 addresses.
```
docker create \
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

Connect the 10.10.10.0/24 network to the BIND container.
```
docker network connect --ip 10.10.10.10 pub bind
```

Start the BIND container.
```
docker start bind
```


# DHCPD
The DHCPD container will be used for generating IP addresses needed by the cluster nodes.

Create the configuration directory.
```
sudo mkdir -p /srv/docker/dhcpd
sudo chmod 777 /srv/docker/dhcpd
```

Copy the dhcpd.conf file to the configuration directory.
```
cp dhcpd.conf /srv/docker/dhcpd/
```

Create the DHCPD container but don't start it until the step following this one is complete.
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


# RAC Node
The RAC node container will be used for the grid infrastructure and database software. This process can be duplicated to create as many nodes as you want in your cluster.

Create the RAC node image.
```
docker build --tag giready Dockerfile-racnode
```

Create the RAC node container. The `/oracledata/stage` directory holds the Oracle installation files. The `/sys/fs/cgroup` directory is necessary for systemd to run in the containers. The grid installation will fail without at least 1.5GB of shared memory.
```
docker run \
--detach \
--privileged \
--name rac1 \
--hostname rac1 \
--volume /oracledata/stage:/stage \
--volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
--dns 10.10.10.10 \
--shm-size 2048m \
giready \
/usr/lib/systemd/systemd --system --unit=multi-user.target
```

Add the two custom networks to the RAC node container. I initially tried to use the `docker network connect` commands that were used for the DHCPD container but the name of the network adapter must be consistent in all the RAC node container and `docker network connect` does not allow you to specify an adapter name. Pipework is essentially doing exactly what `docker network connect` does with the additional abilities to specify the network interface name both inside the container and on the host as well not giving the new adapters IPs so the IPs can come from the dhcpd container. Unlike the native docker network functions, the pipework virtual adapters are not deleted automatically when the container is removed. There can be consequences if you are recreating your RAC containers over and over again without deleting the virtual adapters so the `ip link delete` commands were added to delete any previously existing virtual adapters before creating the new ones needed by the RAC node container. The `ip link delete` commands will error out if these virtual adapters don't yet exist. These errors can be ignored. The `Warning: arping not found` errors can also be ignored. Pipework is using the existing networks instead of creating new ones.
```
sudo ip link delete rac1-pub
sudo /srv/docker/pipework/pipework br-$(docker network ls -q -f NAME=pub) -i eth1 -l rac1-pub rac1 0.0.0.0/24

sudo ip link delete rac1-priv
sudo /srv/docker/pipework/pipework br-$(docker network ls -q -f NAME=priv) -i eth2 -l rac1-priv rac1 0.0.0.0/24
```

Start dhclient for each of the newly added networks. The IPs will come from the dhcpd container which will update the bind container.
```
docker exec rac1 dhclient -H rac1 -pf /var/run/dhclient-eth1.pid eth1
docker exec rac1 dhclient -H rac1-priv -pf /var/run/dhclient-eth2.pid eth2
```

Udev is used in the RAC node containers to give the ASM block devices correct permissions and friendly names. ASMLib could also be used but I stopped using that a couple of years ago because it appears that it will go away at some point in favor of AFD.

Modify the `99-asm-disks.rules` file to reflect the devices on the host system that you have designated as ASM disks. For example, I have designated /dev/sdd, /dev/sde, and /dev/sdf as the three disks that will comprise my DATA ASM disk group.
```
KERNEL=="sdd", SYMLINK+="asmdisks/asm-clu-121-DATA-disk1", GROUP="54321"
KERNEL=="sde", SYMLINK+="asmdisks/asm-clu-121-DATA-disk2", GROUP="54321"
KERNEL=="sdf", SYMLINK+="asmdisks/asm-clu-121-DATA-disk3", GROUP="54321"
```

Copy the file into the RAC node container.
```
docker cp 99-asm-disks.rules rac1:/etc/udev/rules.d/
```

Tell udev to read the new rules configuration.
```
docker exec rac1 udevadm trigger
```

Now my ASM disk devices look like this in the RAC node container.
```
$ docker exec rac1 ls -l /dev/sd[d-f]
brw-rw----. 1 root oinstall 8, 48 Oct 17 16:49 /dev/sdd
brw-rw----. 1 root oinstall 8, 64 Oct 17 16:49 /dev/sde
brw-rw----. 1 root oinstall 8, 80 Oct 17 16:49 /dev/sdf
$ docker exec rac1 ls -ld /dev/asmdisks/
drwxr-xr-x. 2 root root 100 Oct 17 16:49 /dev/asmdisks/
$ docker exec rac1 ls -l /dev/asmdisks/
total 0
lrwxrwxrwx. 1 root root 6 Oct 17 16:49 asm-clu-121-DATA-disk1 -> ../sdd
lrwxrwxrwx. 1 root root 6 Oct 17 16:49 asm-clu-121-DATA-disk2 -> ../sde
lrwxrwxrwx. 1 root root 6 Oct 17 16:49 asm-clu-121-DATA-disk3 -> ../sdf
```

Connect to the RAC node container and execute the grid infrastructure installer. This will install the grid software only.

#### Bug
There is currently a bug that is delaying the systemd startup process which means that systemd won't return a runlevel for up to a few minutes after the container has been started. If you execute the grid infrastructure installer before systemd has started, the installer will return an error that looks like this.
```
INFO: *********************************************
INFO: Run Level: This is a prerequisite condition to test whether the system is running with proper run level.
INFO: Severity:CRITICAL
INFO: OverallStatus:OPERATION_FAILED
```
If this happens, simply restart the grid infrastructure installer. If you want to be sure systemd is done starting up, you can run the command `runlevel` which should return `N 3` or `N 5`.
***

During the installation, you will see the message `Some of the optional prerequisites are not met`. This is normal and a consequence of running in a container.
```
docker exec -it rac1 bash
su - grid

GRID_HOME=/u01/app/12.1.0/grid

/stage/grid/runInstaller -ignoreSysPrereqs -silent -force \
"INVENTORY_LOCATION=/u01/app/oraInventory" \
"UNIX_GROUP_NAME=oinstall" \
"ORACLE_HOME=/u01/app/12.1.0/grid" \
"ORACLE_BASE=/u01/app/oracle" \
"oracle.install.option=CRS_SWONLY" \
"oracle.install.asm.OSDBA=asmdba" \
"oracle.install.asm.OSOPER=" \
"oracle.install.asm.OSASM=asmadmin"
```

Run the two root scripts as root in the RAC node container.
```
/u01/app/oraInventory/orainstRoot.sh
/u01/app/12.1.0/grid/root.sh
```

Exit the RAC node container and create a new image which will be used as the base of any additional RAC node containers.
```
docker commit rac1 giinstalled
```

Create a new RAC node container from the image you just created or just skip this step and continue using the same container.
```
docker rm -f rac1

docker run \
--detach \
--privileged \
--name rac1 \
--hostname rac1 \
--volume /oracledata/stage:/stage \
--volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
--dns 10.10.10.10 \
--shm-size 2048m \
giinstalled \
/usr/lib/systemd/systemd --system --unit=multi-user.target
```

Create the two networks and start dhclient on them as was done earlier. This step does not need to be done if you are continuing to use the same container.
```
sudo ip link delete rac1-pub
sudo /srv/docker/pipework/pipework br-$(docker network ls -q -f NAME=pub) -i eth1 -l rac1-pub rac1 0.0.0.0/24

sudo ip link delete rac1-priv
sudo /srv/docker/pipework/pipework br-$(docker network ls -q -f NAME=priv) -i eth2 -l rac1-priv rac1 0.0.0.0/24

docker exec rac1 dhclient -H rac1 -pf /var/run/dhclient-eth1.pid eth1
docker exec rac1 dhclient -H rac1-priv -pf /var/run/dhclient-eth2.pid eth2
```

Create a second RAC node container.
```
docker run \
--detach \
--privileged \
--name rac2 \
--hostname rac2 \
--volume /oracledata/stage:/stage \
--volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
--dns 10.10.10.10 \
--shm-size 2048m \
giinstalled \
/usr/lib/systemd/systemd --system --unit=multi-user.target
```

Create the two networks and start dhclient on them.
```
sudo ip link delete rac2-pub
sudo /srv/docker/pipework/pipework br-$(docker network ls -q -f NAME=pub) -i eth1 -l rac2-pub rac2 0.0.0.0/24

sudo ip link delete rac2-priv
sudo /srv/docker/pipework/pipework br-$(docker network ls -q -f NAME=priv) -i eth2 -l rac2-priv rac2 0.0.0.0/24

docker exec rac2 dhclient -H rac2 -pf /var/run/dhclient-eth1.pid eth1
docker exec rac2 dhclient -H rac2-priv -pf /var/run/dhclient-eth2.pid eth2
```

Configure shared key SSH authentication among all RAC node containers.
```
./fixssh.sh rac1 rac2
```

Connect to the first RAC node container and configure the installed grid infrastructure. Modify the `oracle.install.asm.diskGroup.disks` and `oracle.install.asm.diskGroup.diskDiscoveryString` parameters to match the ASM block devices from the host.

During the configuration, you will see the message `Some of the optional prerequisites are not met`. This is normal and a consequence of running in a container.
```
docker exec -it rac1 bash
su - grid

GRID_HOME=/u01/app/12.1.0/grid

${GRID_HOME?}/crs/config/config.sh -ignoreSysPrereqs -silent \
"INVENTORY_LOCATION=/u01/app/oraInventory" \
"SELECTED_LANGUAGES=en" \
"oracle.install.option=CRS_CONFIG" \
"ORACLE_BASE=/u01/app/oracle" \
"ORACLE_HOME=/u01/app/12.1.0/grid" \
"oracle.install.asm.OSDBA=asmdba" \
"oracle.install.asm.OSOPER=" \
"oracle.install.asm.OSASM=asmadmin" \
"oracle.install.crs.config.gpnp.scanName=clu-121-scan.clu-121.example.com" \
"oracle.install.crs.config.gpnp.scanPort=1521 " \
"oracle.install.crs.config.ClusterType=STANDARD" \
"oracle.install.crs.config.clusterName=clu-121" \
"oracle.install.crs.config.gpnp.configureGNS=true" \
"oracle.install.crs.config.autoConfigureClusterNodeVIP=true" \
"oracle.install.crs.config.gpnp.gnsOption=CREATE_NEW_GNS" \
"oracle.install.crs.config.gpnp.gnsSubDomain=clu-121.example.com" \
"oracle.install.crs.config.gpnp.gnsVIPAddress=clu-121-gns.example.com" \
"oracle.install.crs.config.clusterNodes=rac1.example.com:AUTO,rac2.example.com:AUTO" \
"oracle.install.crs.config.networkInterfaceList=eth1:10.10.10.0:1,eth2:11.11.11.0:2" \
"oracle.install.crs.config.storageOption=LOCAL_ASM_STORAGE" \
"oracle.install.crs.config.useIPMI=false" \
"oracle.install.asm.SYSASMPassword=oracle_4U" \
"oracle.install.asm.monitorPassword=oracle_4U" \
"oracle.install.asm.diskGroup.name=DATAC1" \
"oracle.install.asm.diskGroup.redundancy=EXTERNAL" \
"oracle.install.asm.diskGroup.disks=/dev/asmdisks/asm-clu-121-DATA-disk1,/dev/asmdisks/asm-clu-121-DATA-disk2,/dev/asmdisks/asm-clu-121-DATA-disk3" \
"oracle.install.asm.diskGroup.diskDiscoveryString=/dev/asmdisks/*" \
"oracle.install.asm.useExistingDiskGroup=false"
```

Run the root script as the root user on the first RAC node container, then the second. Wait for the first to complete before running the second.
```
/u01/app/12.1.0/grid/root.sh
```

Copy the configuration assistant response file into the first RAC node container. Change the passwords in the file if necessary before copying.
```
docker cp tools_config.rsp rac1:/tmp/
```

Run the configuration assistant on the first RAC node container only.
```
su - grid

GRID_HOME=/u01/app/12.1.0/grid

${GRID_HOME?}/cfgtoollogs/configToolAllCommands RESPONSE_FILE=/tmp/tools_config.rsp
```

Disconnect from the RAC node container and delete the configuration assistant response file.
```
docker exec rac1 rm -f /tmp/tools_config.rsp
```
