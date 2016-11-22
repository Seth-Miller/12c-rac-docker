# Ansible
Ansible will be used to set automate the setup and configuration of the project. Ansible will be running from your workstation or a remote server with SSH access to the host running the containers. These instructions assume the host OS is already running and configured correctly.

# Download Ansible
The requirements and instructions for Ansible can be found [here] (http://docs.ansible.com/ansible/intro_installation.html).


# Ansible Inventory
Add the Docker host IP to the Ansible inventory.
```




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


