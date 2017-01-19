# 12c-rac-docker
Multiple node Oracle RAC cluster running in Docker containers.

## How to use
This setup uses block devices for the ASM DATA diskgroup which the grid infrastructure requires during installation. The recommendation is to use three disks that are at least 4GB each in size.

It is important when creating the BIND and DHCPD containers that the BIND container is created first. The reason is that there is a key created as part of the BIND image build that DHCPD will use for dynamic dns updates and the key needs to exist when the DHCPD container is created.

The passwords for the non-privileged user accounts are all set to `oracle_4U`.

This project was built using CoreOS. See the [COREOS.md] (https://github.com/Seth-Miller/12c-rac-docker/blob/master/COREOS.md) file for instructions on how to use CoreOS for this project.


## Oracle installation files
Download the Oracle 12c Grid Infrastructure and Database installation files and unzip them in a directory on the host. The directory will be mounted as a volume in the RAC node containers for installation. The host directory used in this example is `/oracledata/stage`. Once unzipped, there should be a `grid` and `database` folder in `/oracledata/stage`.


## ASM
Udev is used in the RAC node containers to give the ASM block devices correct permissions and friendly names. ASMLib could also be used but I stopped using that a couple of years ago because it appears that it will go away at some point in favor of ASM Filter Driver (AFD).

Modify the `99-asm-disks.rules` file to reflect the devices on the host system that you have designated as ASM disks. For example, I have designated /dev/sdd, /dev/sde, and /dev/sdf as the three disks that will be used in my DATA ASM disk group.
```
KERNEL=="sdd", SYMLINK+="asmdisks/asm-clu-121-DATA-disk1", OWNER="54421", GROUP="54422"
KERNEL=="sde", SYMLINK+="asmdisks/asm-clu-121-DATA-disk2", OWNER="54421", GROUP="54422"
KERNEL=="sdf", SYMLINK+="asmdisks/asm-clu-121-DATA-disk3", OWNER="54421", GROUP="54422"
```

NFS is used in the RAC node containers for the NDATA ASM disk group which uses file devices over NFS. The directory on the host OS that will be shared across the RAC node containers is `/oraclenfs`. Create three files on the host OS using `dd`.
```
sudo dd if=/dev/zero of=/oraclenfs/asm-clu-121-NDATA-disk1 bs=1024k count=2000
sudo dd if=/dev/zero of=/oraclenfs/asm-clu-121-NDATA-disk2 bs=1024k count=2000
sudo dd if=/dev/zero of=/oraclenfs/asm-clu-121-NDATA-disk3 bs=1024k count=2000

sudo chown 54421 /oraclenfs/asm*
sudo chgrp 54422 /oraclenfs/asm*
sudo chmod g+w /oraclenfs/asm*
```


## Networks

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


## BIND
The BIND container will be used for DNS for the cluster.

Create the BIND container. Unless you need it, disable the administration GUI `--env WEBMIN_ENABLED=false`. The `-4` option prevents the named/bind process from listening on the IPV6 networks.
```
docker run \
--detach \
--name bind \
--hostname bind \
--network pub \
--ip 10.10.10.10 \
--publish 53:53/tcp \
--publish 53:53/udp \
--volume /srv/docker/bind:/data \
--env WEBMIN_ENABLED=false \
sethmiller/bind \
-4
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


# NFS
The NFS server will share a host OS directory with the RAC node containers over NFS. The NFS server will be connected to the RAC node containers through a Docker link.

Create the configuration directory.
```
sudo mkdir -p /srv/docker/nfs
sudo chmod 777 /srv/docker/nfs
```

Copy the ganesha.conf file to the configuration directory.
```
cp ganesha.conf /srv/docker/nfs/
```

Create the NFS container.
```
docker run \
--interactive \
--tty \
--detach \
--privileged \
--name nfs \
--hostname nfs \
--volume /srv/docker/nfs:/etc/ganesha \
--volume /oraclenfs:/oraclenfs \
--dns 10.10.10.10 \
sethmiller/nfs
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

Alternatively, pull the RAC node image that has already been built.
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
sethmiller/giready \
/usr/lib/systemd/systemd --system --unit=multi-user.target
```

Add the two custom networks to the RAC node container. I initially tried to use the `docker network connect` commands that were used for the DHCPD container but the name of the network adapter must be consistent in all the RAC node container and `docker network connect` does not allow you to specify an adapter name. I used to use a script called pipework but the results were inconsistent so I found the network namespace commands it was using and put them into individual scripts.

Unlike the native docker network functions, the virtual adapters are not deleted automatically when the container is removed. There can be consequences if you are recreating your RAC containers over and over again without deleting the virtual adapters so the `ip link delete` commands were added to the scripts to delete any previously existing virtual adapters before creating the new ones needed by the RAC node container.
```
sudo ./networks-rac1.sh
```

Start dhclient for each of the newly added networks. The IPs will come from the dhcpd container which will update the bind container.
```
docker exec rac1 dhclient -H rac1 -pf /var/run/dhclient-eth1.pid eth1
docker exec rac1 dhclient -H rac1-priv -pf /var/run/dhclient-eth2.pid eth2
```

Copy the udev configuration file for the ASM disks into the RAC node container.
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

***
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

Connect to the RAC node container and execute the grid infrastructure installer. This will install the grid software only.

During the installation, you will see the message `Some of the optional prerequisites are not met`. This is normal and a consequence of running in a container.
```
docker exec rac1 su - grid -c ' \
/stage/grid/runInstaller -ignoreSysPrereqs -silent -force \
"INVENTORY_LOCATION=/u01/app/oraInventory" \
"UNIX_GROUP_NAME=oinstall" \
"ORACLE_HOME=/u01/app/12.1.0/grid" \
"ORACLE_BASE=/u01/app/grid" \
"oracle.install.option=CRS_SWONLY" \
"oracle.install.asm.OSDBA=asmdba" \
"oracle.install.asm.OSOPER=" \
"oracle.install.asm.OSASM=asmadmin"'
```

Run the two root scripts as root in the RAC node container.
```
docker exec rac1 /u01/app/oraInventory/orainstRoot.sh
docker exec rac1 /u01/app/12.1.0/grid/root.sh
```

Connect to the RAC node container and execute the database installer. This will install the database software only.

During the installation, you will see the message `Some of the optional prerequisites are not met`. This is normal and a consequence of running in a container.
```
docker exec rac1 su - oracle -c ' \
/stage/database/runInstaller -ignoreSysPrereqs -silent -force \
"oracle.install.option=INSTALL_DB_SWONLY" \
"INVENTORY_LOCATION=/u01/app/oraInventory" \
"UNIX_GROUP_NAME=oinstall" \
"ORACLE_HOME=/u01/app/oracle/product/12.1.0/dbhome_1" \
"ORACLE_BASE=/u01/app/oracle" \
"oracle.install.db.InstallEdition=EE" \
"oracle.install.db.DBA_GROUP=dba" \
"oracle.install.db.BACKUPDBA_GROUP=dba" \
"oracle.install.db.DGDBA_GROUP=dba" \
"oracle.install.db.KMDBA_GROUP=dba" \
"oracle.install.db.CLUSTER_NODES=rac1" \
"DECLINE_SECURITY_UPDATES=true"'
```

Run the root script as root in the RAC node container.
```
docker exec rac1 /u01/app/oracle/product/12.1.0/dbhome_1/root.sh
```

Exit the RAC node container and create a new image which will be used as the base of any additional RAC node containers.
```
docker commit rac1 giinstalled
```

Create a new RAC node container from the image you just created.
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
--link nfs:nfs \
--shm-size 2048m \
giinstalled \
/usr/lib/systemd/systemd --system --unit=multi-user.target
```

Create the two networks and start dhclient on them as was done earlier. This step does not need to be done if you are continuing to use the same container.
```
sudo ./networks-rac1.sh

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
--link nfs:nfs \
--shm-size 2048m \
giinstalled \
/usr/lib/systemd/systemd --system --unit=multi-user.target
```

Create the two networks and start dhclient on them.
```
sudo ./networks-rac2.sh

docker exec rac2 dhclient -H rac2 -pf /var/run/dhclient-eth1.pid eth1
docker exec rac2 dhclient -H rac2-priv -pf /var/run/dhclient-eth2.pid eth2
```

Configure shared key SSH authentication among all RAC node containers.
```
./fixssh.sh rac1 rac2
```

Connect to the first RAC node container and configure the installed grid infrastructure.

During the configuration, you will see the message `Some of the optional prerequisites are not met`. This is normal and a consequence of running in a container.
```
docker exec rac1 su - grid -c ' \
/u01/app/12.1.0/grid/crs/config/config.sh -ignoreSysPrereqs -silent \
"INVENTORY_LOCATION=/u01/app/oraInventory" \
"SELECTED_LANGUAGES=en" \
"oracle.install.option=CRS_CONFIG" \
"ORACLE_BASE=/u01/app/grid" \
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
"oracle.install.asm.diskGroup.name=DATA" \
"oracle.install.asm.diskGroup.redundancy=EXTERNAL" \
"oracle.install.asm.diskGroup.disks=/dev/asmdisks/asm-clu-121-DATA-disk1,/dev/asmdisks/asm-clu-121-DATA-disk2,/dev/asmdisks/asm-clu-121-DATA-disk3" \
"oracle.install.asm.diskGroup.diskDiscoveryString=/dev/asmdisks/*" \
"oracle.install.asm.useExistingDiskGroup=false"'
```

Run the root script as the root user on the first RAC node container, then the second. Wait for the first to complete before running the second.
```
docker exec rac1 /u01/app/12.1.0/grid/root.sh
docker exec rac2 /u01/app/12.1.0/grid/root.sh
```

Copy the configuration assistant response file into the first RAC node container. Change the passwords in the file if necessary before copying.
```
docker cp tools_config.rsp rac1:/tmp/
```

Run the configuration assistant on the first RAC node container only.
```
docker exec rac1 su - grid -c '/u01/app/12.1.0/grid/cfgtoollogs/configToolAllCommands RESPONSE_FILE=/tmp/tools_config.rsp'
```

Delete the configuration assistant response file.
```
docker exec rac1 rm -f /tmp/tools_config.rsp
```

Configure the database installations for the cluster.
```
docker exec rac1 su - oracle -c '/u01/app/oracle/product/12.1.0/dbhome_1/addnode/addnode.sh -silent -ignoreSysPrereqs -noCopy CLUSTER_NEW_NODES={rac2}'
docker exec rac1 /u01/app/oracle/product/12.1.0/dbhome_1/root.sh
docker exec rac2 /u01/app/oracle/product/12.1.0/dbhome_1/root.sh
```

Optionally, create a database.
```
docker exec rac1 su - oracle -c ' \
/u01/app/oracle/product/12.1.0/dbhome_1/bin/dbca -createDatabase -silent \
-templateName General_Purpose.dbc \
-gdbName orcl \
-sysPassword oracle_4U \
-systemPassword oracle_4U \
-storageType ASM \
-diskGroupName DATA \
-recoveryGroupName DATA \
-characterSet AL32UTF8 \
-nationalCharacterSet UTF8 \
-totalMemory 1024 \
-emConfiguration none \
-nodelist rac1,rac2 \
-createAsContainerDatabase True'
```

Optionally, create the NDATA ASM disk group.
This currently isn't working because Oracle doesn't seem to like the user space NFS server.
```
docker cp oraclenfs.mount rac1:/etc/systemd/system/
docker cp oraclenfs.mount rac2:/etc/systemd/system/

docker exec rac1 systemctl daemon-reload
docker exec rac2 systemctl daemon-reload

docker exec rac1 systemctl start oraclenfs.mount
docker exec rac2 systemctl start oraclenfs.mount

docker exec rac1 su - grid -c "ORACLE_SID=+ASM1 /u01/app/12.1.0/grid/bin/asmcmd dsset '\
/dev/asmdisks/*,/oraclenfs/asm*'"

docker exec rac1 su - grid -c "ORACLE_SID=+ASM1 /u01/app/12.1.0/grid/bin/asmcmd mkdg '\
  <dg name=\"NDATA\" redundancy=\"external\"> \
  <dsk string=\"/oraclenfs/asm-clu-121-NDATA-disk1\"/> \
  <dsk string=\"/oraclenfs/asm-clu-121-NDATA-disk2\"/> \
  <dsk string=\"/oraclenfs/asm-clu-121-NDATA-disk3\"/> \
</dg>'"
```   

Confirm the resources are running.
```
docker exec rac1 /u01/app/12.1.0/grid/bin/crsctl status resource -t
```

***
If the ASM disks have existing headers that you want to clear, use dd to wipe out the headers.
!!!WARNING!!! This will destroy these disks and anything on them. Make sure you are clearing the right disks.
```
for i in sdd sde sdf; do
  sudo dd if=/dev/zero of=/dev/$i bs=100M count=1
done
```
