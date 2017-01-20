# Ansible orchestration for 12c RAC in Docker Containers
Multiple node Oracle RAC cluster running in Docker containers.


## Setup
If you're running CoreOS for your Docker host, some setup is required before proceeding. Instructions can be found in [ANSIBLE_SETUP.md] (https://github.com/Seth-Miller/12c-rac-docker/blob/master/ANSIBLE_SETUP.md)


## Ansible
All of the ansible scripts are in the [ansible] (https://github.com/Seth-Miller/12c-rac-docker/tree/master/ansible) directory in this repository. Throughout these instructions it is assumed you are working from the ansible directory.

Besides the instructions found here, the yaml files are heavily commented with information and examples.

The tasks in the Ansible roles follow very closely to the instructions found in the [README.md] (https://github.com/Seth-Miller/12c-rac-docker/blob/master/README.md).


## Common Variables
The variables for all of the roles are contained in the [roles/common/vars] (https://github.com/Seth-Miller/12c-rac-docker/tree/master/ansible/roles/common/vars) directory. All of the roles reference variables in the [main.yml] (https://github.com/Seth-Miller/12c-rac-docker/blob/master/ansible/roles/common/vars/main.yml) file.

There is a second file called [files.yml] (https://github.com/Seth-Miller/12c-rac-docker/blob/master/ansible/roles/common/vars/files.yml) that is referenced for the file locations of the grid infrastructure and database installation files. This file was left intentionally blank so you can fill out the locations for these files based on your environment.

It is important that all of the playbooks reference the common role as well as the files.yml file.
```
vars_files:
  - roles/common/vars/files.yml
roles:
  - common
```


## Prepare the Docker host
The [prepare_host.yml] (https://github.com/Seth-Miller/12c-rac-docker/blob/master/ansible/prepare_host.yml) file starts the prepare_host role. These tasks not only prepare the Docker host, they also build the containers that support the Oracle RAC cluster, including the DNS/BIND, DHCPD, and NFS server containers.

Run the prepare_host playbook.
```
ansible-playbook prepare_host.yml
```

Tags can be used to limit which tasks are executed in each playbook. If you want to only prepare the ASM file and block devices, add the `asm` tag.
```
ansible-playbook prepare_host.yml --tags=asm
```

Here is a list of tags and their descriptions for the prepare_host tasks.

Tag           | Description
------------- | --------------------------------------
asm | Manage the ASM block and file devices
create_docker_networks | Creates public and private Docker networks
create_directory | Creates directories for container configuration files
config_files | Copies config files to DHCPD and NFS containers
create_container | Creates the BIND, DHCPD, and NFS containers
installation_files | Downloads and unzips the Oracle installation files
