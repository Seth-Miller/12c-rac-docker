# CoreOS
This repository was created and built on CoreOS. It was the intention of this project to not only run Oracle RAC in Docker containers but to have all of the supporting elements running in Docker containers as well. Other than the Docker and shared storage, there is nothing on the host OS that cannot easily be recreated.

https://coreos.com/docs/

Once the VM is running, the IP you will use to connect an ssh client will be displayed on the VM console. If you are following the instructions below and using port forwarding, you will connect to 127.0.0.1 on port 2222. Connect to the VM over SSH with the username `core` using shared key authentication.

## Cloud Config
The configuration file for CoreOS needs to be mounted as an ISO to the VM which means you will need a utility to create an ISO. The recommendation is to use mkisofs which is part of the open source cdrtools. This is in most Linux repos and can be added to Cygwin. If you are on Windows, it can be downloaded from [here] (http://sourceforge.net/projects/tumagcc/files/schily-cdrtools-3.02a05.7z/download).

The cloud config file must be named `user_data` and the path to the user_data file on the ISO must be `/openstack/latest/user_data`. Download the cloud-config file from this repository and modify the ssh_authorized_keys to reflect your SSH public key.

Execute these steps to create the ISO on Windows.
```
mkdir coreos\cloud-config\openstack\latest\
copy cloud-config coreos\cloud-config\openstack\latest\user_data
mkisofs.exe -R -V config-2 -o coreos/mycoreos.iso coreos/cloud-config
```

Execute these steps to create the ISO on Linux or Cygwin.
```
mkdir -p coreos/cloud-config/openstack/latest/
cp cloud-config coreos/cloud-config/openstack/latest/user_data
mkisofs -R -V config-2 -o coreos/mycoreos.iso coreos/cloud-config
```


## CoreOS VM
CoreOS can be deployed on a number of different platforms. This project at a minimum will require the VM have these specifications.
- 1 network interface accessible from SSH client
- Memory 8 GB
- Two additional 100 GB thin provisioned hard disks
- Three additional 8 GB thin provisioned hard disks


## VirtualBox
Download the latest stable release of the virtual disk image.
https://stable.release.core-os.net/amd64-usr/current/coreos_production_image.bin.bz2

Set environment variables in Windows CLI
```
REM Set the VBOXMANAGE variable to the full path of VBoxManage.exe
set VBOXMANAGE="C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

REM Set the MACHINE_FOLDER variable to the VirtualBox Machine Folder setting
REM By default the machine folder setting is "%HOMEDRIVE%%HOMEPATH%\VirtualBox VMs"
set MACHINE_FOLDER=%HOMEDRIVE%%HOMEPATH%\VirtualBox VMs

REM Set the COREOS_VM_NAME variable to the name of the VM you are going to create
set COREOS_VM_NAME=mycoreos 

REM Set the CLOUD_CONFIG variable to the full path of the cloud-config ISO
set CLOUD_CONFIG=C:\coreos\mycoreos.iso
```

Unzip the download file using the open source bzip2 library. 7zip does not work for this. If you are using windows, a precompiled bzip2 download can be found [here] (http://gnuwin32.sourceforge.net/downlinks/bzip2-bin-zip.php).
```
bunzip2 coreos_production_image.bin.bz2
```

Convert the bin to a virtual disk image (VDI) using VBoxManage.
```
%VBOXMANAGE% convertfromraw coreos_production_image.bin coreos_production_image.vdi
```

Create the VM.
```
%VBOXMANAGE% createvm --name %COREOS_VM_NAME% --register --ostype "Linux26_64"
```

Clone the downloaded CoreOS image into the VM folder.
```
%VBOXMANAGE% clonemedium coreos_production_image.vdi "%MACHINE_FOLDER%\%COREOS_VM_NAME%\%COREOS_VM_NAME%_production_image.vdi" 
```

Optionally resize the disk to 10 GB. This will leave room to add modifications to the OS.
```
%VBOXMANAGE% modifymedium "%MACHINE_FOLDER%\%COREOS_VM_NAME%\%COREOS_VM_NAME%_production_image.vdi" --resize 10240
```

Create an additional thin provisioned disk for Docker storage.
```
%VBOXMANAGE% createmedium disk --filename "%MACHINE_FOLDER%\%COREOS_VM_NAME%\%COREOS_VM_NAME%_docker.vdi" --size 102400
```

Create an additional thin provisioned disk for Oracle installation file storage.
```
%VBOXMANAGE% createmedium disk --filename "%MACHINE_FOLDER%\%COREOS_VM_NAME%\%COREOS_VM_NAME%_oracledata.vdi" --size 102400
```

Create additional thin provisioned disks for ASM disk devices.
```
%VBOXMANAGE% createmedium disk --filename "%MACHINE_FOLDER%\%COREOS_VM_NAME%\%COREOS_VM_NAME%_ASM_DATA1.vdi" --size 8192
%VBOXMANAGE% createmedium disk --filename "%MACHINE_FOLDER%\%COREOS_VM_NAME%\%COREOS_VM_NAME%_ASM_DATA2.vdi" --size 8192
%VBOXMANAGE% createmedium disk --filename "%MACHINE_FOLDER%\%COREOS_VM_NAME%\%COREOS_VM_NAME%_ASM_DATA3.vdi" --size 8192
```

Add a storage controller to the VM.
```
%VBOXMANAGE% storagectl %COREOS_VM_NAME% --name "SATA" --add sata
```

Add an additional IDE storage controller to the VM
```
%VBOXMANAGE% storagectl %COREOS_VM_NAME% --name "IDE" --add ide
```

Attach the disks to the SATA storage controller.
```
%VBOXMANAGE% storageattach %COREOS_VM_NAME% --storagectl "SATA" --type hdd --port 0 --medium "%MACHINE_FOLDER%\%COREOS_VM_NAME%\%COREOS_VM_NAME%_production_image.vdi"
%VBOXMANAGE% storageattach %COREOS_VM_NAME% --storagectl "SATA" --type hdd --port 1 --medium "%MACHINE_FOLDER%\%COREOS_VM_NAME%\%COREOS_VM_NAME%_docker.vdi"
%VBOXMANAGE% storageattach %COREOS_VM_NAME% --storagectl "SATA" --type hdd --port 2 --medium "%MACHINE_FOLDER%\%COREOS_VM_NAME%\%COREOS_VM_NAME%_oracledata.vdi"
%VBOXMANAGE% storageattach %COREOS_VM_NAME% --storagectl "SATA" --type hdd --port 3 --medium "%MACHINE_FOLDER%\%COREOS_VM_NAME%\%COREOS_VM_NAME%_ASM_DATA1.vdi"
%VBOXMANAGE% storageattach %COREOS_VM_NAME% --storagectl "SATA" --type hdd --port 4 --medium "%MACHINE_FOLDER%\%COREOS_VM_NAME%\%COREOS_VM_NAME%_ASM_DATA2.vdi"
%VBOXMANAGE% storageattach %COREOS_VM_NAME% --storagectl "SATA" --type hdd --port 5 --medium "%MACHINE_FOLDER%\%COREOS_VM_NAME%\%COREOS_VM_NAME%_ASM_DATA3.vdi"
```

Attach the cloud-config ISO to the IDE storage controller
```
%VBOXMANAGE% storageattach %COREOS_VM_NAME% --storagectl "IDE" --type dvddrive --port 0 --medium %CLOUD_CONFIG% --device 0
```

Change the VM memory to a minimum of 8 GB
```
%VBOXMANAGE% modifyvm %COREOS_VM_NAME% --memory 8192
```

Create a port forwarding rule to connect a local ssh client to the NAT network
```
%VBOXMANAGE% modifyvm %COREOS_VM_NAME% --natpf1 "guestssh,tcp,127.0.0.1,2222,,22"

```



# TODO

## VMware
CoreOS provides pre-built OVA templates for VMware which makes it tremendously easy to both deploy and configure. Refer to the CoreOS documentation for additional details `https://coreos.com/os/docs/latest/booting-on-vmware.html`.

Download the latest stable release of the OVA.
https://stable.release.core-os.net/amd64-usr/current/coreos_production_vmware_ova.ova

### ESXi
Use the vSphere Client to deploy the VM as follows:
1. In the menu, click `File` > `Deploy OVF Template...`
2. In the wizard, specify the location of the OVA file downloaded earlier
3. Name your VM
4. Choose "thin provision" for the disk format
5. Choose your network settings
6. Confirm the settings, then click "Finish"


