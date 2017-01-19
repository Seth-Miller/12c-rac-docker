# Ansible orchestration for 12c RAC in Docker Containers
Multiple node Oracle RAC cluster running in Docker containers.


## Setup
If you're running CoreOS for your Docker host, some setup is required before proceeding. Instructions can be found in [ANSIBLE_SETUP.md] (https://github.com/Seth-Miller/12c-rac-docker/blob/master/ANSIBLE_SETUP.md)


## Ansible
Everything required for Ansible to work is in the [ansible] (https://github.com/Seth-Miller/12c-rac-docker/tree/master/ansible) subfolder in this repository. Throughout these instructions it is assumed you are working from the ansible directory.

Besides the instructions found here, the yaml files are heavily commented with information and examples.

The tasks in the Ansible roles follow very closely to the instructions found in the [README.md] (https://github.com/Seth-Miller/12c-rac-docker/blob/master/README.md).


## Common Variables
The variables for all of the roles are contained in the [roles/common/vars] (https://github.com/Seth-Miller/12c-rac-docker/tree/master/ansible/roles/common/vars) directory. All of the roles reference variables in the [main.yml] (https://github.com/Seth-Miller/12c-rac-docker/blob/master/ansible/roles/common/vars/main.yml) file.

There is a second file called [files.yml] (https://github.com/Seth-Miller/12c-rac-docker/blob/master/ansible/roles/common/vars/files.yml) that is referenced for the file locations of the grid infrastructure and database installation files. This file was left intentionally blank so you can fill out the locations for these files based on your environment.


## Prepare the Docker host
The `prepare_host.yml` file starts the prepare_host role. These tasks not only prepare the Docker host, they also build the containers that support the Oracle RAC cluster, including the DNS/BIND, DHCPD, and NFS server containers.
