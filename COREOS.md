# CoreOS
This repository was created and built on CoreOS. It was the intention of this project to not only run Oracle RAC in Docker containers but to have all of the supporting elements running in Docker containers as well. Other than the Docker and shared storage, there is nothing on the host OS that cannot easily be recreated.

https://coreos.com/docs/

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
```

Convert the compressed bin to a virtual disk image (VDI) using VBoxManage.
```
%VBOXMANAGE% convertfromraw coreos_production_image.bin.bz2 coreos_production_image.vdi
```

Optionally resize the image to 10 MB.
```
%VBOXMANAGE% modifyhd coreos_production_image.vdi --resize 10240
```

Create the VM.
```
%VBOXMANAGE% createvm --name %COREOS_VM_NAME% --register --ostype "Linux26_64"
```

Clone the downloaded CoreOS image into the VM folder.
```
%VBOXMANAGE% clonemedium coreos_production_image.vdi "%MACHINE_FOLDER%\%COREOS_VM_NAME%\%COREOS_VM_NAME%_production_image.vdi" 
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

Attach an empty DVD drive to the IDE storage controller
```
%VBOXMANAGE% storageattach %COREOS_VM_NAME% --storagectl "IDE" --type dvddrive --port 0 --medium emptydrive --device 0
```

Attach the disks to the VM.
```
%VBOXMANAGE% storageattach %COREOS_VM_NAME% --storagectl "SATA" --type hdd --port 0 --medium "%MACHINE_FOLDER%\%COREOS_VM_NAME%\%COREOS_VM_NAME%_production_image.vdi"
%VBOXMANAGE% storageattach %COREOS_VM_NAME% --storagectl "SATA" --type hdd --port 1 --medium "%MACHINE_FOLDER%\%COREOS_VM_NAME%\%COREOS_VM_NAME%_oracledata.vdi"
%VBOXMANAGE% storageattach %COREOS_VM_NAME% --storagectl "SATA" --type hdd --port 2 --medium "%MACHINE_FOLDER%\%COREOS_VM_NAME%\%COREOS_VM_NAME%_ASM_DATA1.vdi"
%VBOXMANAGE% storageattach %COREOS_VM_NAME% --storagectl "SATA" --type hdd --port 3 --medium "%MACHINE_FOLDER%\%COREOS_VM_NAME%\%COREOS_VM_NAME%_ASM_DATA2.vdi"
%VBOXMANAGE% storageattach %COREOS_VM_NAME% --storagectl "SATA" --type hdd --port 4 --medium "%MACHINE_FOLDER%\%COREOS_VM_NAME%\%COREOS_VM_NAME%_ASM_DATA3.vdi"
```

Change the VM memory to a minimum of 8 GB
```
%VBOXMANAGE% modifyvm %COREOS_VM_NAME% --memory 8192
```




Create the VM with the following specifications:
- Memory 8 GB
- Two additional 100 GB thin provisioned hard disks
- Three additional 8 GB thin provisioned hard disks

