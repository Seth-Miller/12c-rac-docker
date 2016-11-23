# Ansible
Ansible will be used to set automate the setup and configuration of the project. Ansible will be running from your workstation or a remote server with SSH access to the host running the containers. These instructions assume the host OS is already running and configured correctly.

### Download Ansible
The requirements and instructions for Ansible can be found [here] (http://docs.ansible.com/ansible/intro_installation.html).


# Docker

### Docker API
This project requires the Docker API be installed on the Ansible host.
```
sudo pip install --upgrade pip
sudo pip install --upgrade setuptools
sudo pip install docker-py
```

### Docker remote access
The Docker daemon running on the Docker host must be configured for TCP access. If you are using the CoreOS setup from this project, TCP access for Docker has already been configured.


# SSH
Establish SSH shared key authentication between the Ansible host and the Docker host.

Generate an SSH key pair on the Ansible host if necessary.
```
ssh-keygen
```

Copy the SSH public key to the Docker host.
```
ssh-copy-id core@<Docker host>
```

If the Docker host is CoreOS, you'll probably need to manually add the public key since password authentication is disabled by default. Add the public key to your cloud-config file under `ssh_authorized_keys:`. Reboot the Docker host or manually add the public key.
```
update-ssh-keys -a ansible << EOF
<your SSH public key>
EOF
```

Establish an SSH connection between the Ansible host and the Docker host to populate the known_hosts file.
```
ssh core@<IP of Docker host>
```


# Ansible Inventory
Add the Docker host IP to the Ansible inventory. If you're using CoreOS, a couple of variables need to be set as part of the host definition as well.
```
<hostname or IP of Docker host>  ansible_ssh_user=core  ansible_python_interpreter=/home/core/bin/python
```


# CoreOS Bootstrap
CoreOS is an intentionally lean OS and doesn't include an installation of Python which Ansible relies on heavily. If you're using CoreOS, you'll need to bootstrap the OS with a minimal installation of Python called Pypy. Fortunately, the CoreOS developers have developed an easy method to make this work. More info can be found [here] (https://github.com/defunctzombie/ansible-coreos-bootstrap).

### Install the CoreOS bootstrap
```
ansible-galaxy install defunctzombie.coreos-bootstrap
```

### Run the bootstrap
Update the `hosts: ` line of the coreos-bootstrap.yml file to reflect the CoreOS hosts you want to bootstrap. If you only have your CoreOS Docker host defined in your Ansible hosts file, use the file the way it is and it will update all of the hosts in your Ansible hosts file.
```
ansible-playbook coreos-bootstrap.yml
```

Verify ansible is working with these commands.
```
ansible all -m setup
ansible all -m ping
```
