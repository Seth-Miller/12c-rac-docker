# Ansible Setup for 12c RAC in Docker Containers
Multiple node Oracle RAC cluster running in Docker containers.



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
