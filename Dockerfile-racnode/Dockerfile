FROM oraclelinux:7.2
MAINTAINER sethmiller.sm@gmail.com


# Passwords for grid and oracle users
ENV ["GRID_PASSWORD", "oracle_4U"]
ENV ["ORACLE_PASSWORD", "oracle_4U"]


###################################################################################
##  System Updates
###################################################################################

# Update the operating system
RUN ["yum", "-y", "update"]


# Add the oracle YUM public repositories
ADD ["http://public-yum.oracle.com/public-yum-ol7.repo", "/etc/yum.repos.d/"]


# Download and import the gpg key
ADD ["http://public-yum.oracle.com/RPM-GPG-KEY-oracle-ol7", "/etc/yum.repos.d/"]
RUN ["rpm", "--import", "/etc/yum.repos.d/RPM-GPG-KEY-oracle-ol7"]


# Install necessary packages
RUN ["yum", "-y", "install", \
       "oracle-rdbms-server-12cR1-preinstall", \
       "vim", \
       "net-tools", \
       "tigervnc-server", \
       "xterm", \
       "iscsi-initiator-utils", \
       "elfutils-libelf-devel", \
       "motif", \
       "lshw", \
       "python-pip", \
       "tar"]


# Clean the yum cache
RUN ["yum", "clean", "all"]


###################################################################################
##  Users and Groups
###################################################################################

# Add groups for grid infrastructure
RUN ["groupadd", "--force", "--gid", "54321", "oinstall"]
RUN ["groupmod", "--gid", "54321", "oinstall"]
RUN ["groupadd", "--gid", "54421", "asmdba"]
RUN ["groupadd", "--gid", "54422", "asmadmin"]
RUN ["groupadd", "--gid", "54423", "asmoper"]


# Add groups for database
RUN ["groupadd", "--force", "--gid", "54322", "dba"]
RUN ["groupmod", "--gid", "54322", "dba"]
RUN ["groupadd", "--gid", "54323", "oper"]
RUN ["groupadd", "--gid", "54324", "backupdba"]
RUN ["groupadd", "--gid", "54325", "dgdba"]
RUN ["groupadd", "--gid", "54326", "kmdba"]
RUN ["groupadd", "--gid", "54327", "racdba"]


# Add grid infrastructure owner
RUN useradd --create-home --uid 54421 --gid oinstall --groups dba,asmdba,asmadmin,asmoper grid || \
    (RES=$? && ( [ $RES -eq 9 ] && exit 0 || exit $RES))
RUN ["usermod", "--uid", "54421", "--gid", "oinstall", "--groups", "dba,asmdba,asmadmin,asmoper", "grid"]


# Add database owner
RUN useradd --create-home --uid 54321 --gid oinstall --groups dba,asmdba,oper,backupdba,dgdba,kmdba,racdba oracle || \
    (RES=$? && ( [ $RES -eq 9 ] && exit 0 || exit $RES))
RUN ["usermod", "--uid", "54321", "--gid", "oinstall", "--groups", "dba,asmdba,oper,backupdba,dgdba,kmdba,racdba", "oracle"]


# Give grid and oracle users passwords
RUN echo "grid:${GRID_PASSWORD}" | chpasswd
RUN echo "oracle:${ORACLE_PASSWORD}" | chpasswd


# Add ulimits configuration file for grid user
# oracle user ulimits configuration file already added by oracle-rdbms-server-12cR1-preinstall
ADD ["grid_security_limits.conf", "/etc/security/limits.d/"]


###################################################################################
##  SSH Shared Keys
###################################################################################

# Create SSH shared key directory for the oracle user
RUN ["mkdir", "-p", "-m", "0700", "/home/oracle/.ssh/"]


# Generate SSH shared keys for the oracle user
RUN ssh-keygen -q -C '' -N '' -f /home/oracle/.ssh/id_rsa


# Create the authorized_keys file for the oracle user
RUN cat /home/oracle/.ssh/id_rsa.pub > /home/oracle/.ssh/authorized_keys


# Change ownership of the SSH shared key files for the oracle user
RUN chown -R oracle:oinstall /home/oracle/.ssh


# Change permissions of the authorized_keys file for the oracle user
RUN ["chmod", "0640", "/home/oracle/.ssh/authorized_keys"]


# Create SSH shared key directory for the grid user
RUN ["mkdir", "-p", "-m", "0700", "/home/grid/.ssh/"]


# Generate SSH shared keys for the grid user
RUN ssh-keygen -q -C '' -N '' -f /home/grid/.ssh/id_rsa


# Create the authorized_keys file for the grid user
RUN cat /home/grid/.ssh/id_rsa.pub > /home/grid/.ssh/authorized_keys


# Change ownership of the SSH shared key files for the grid user
RUN chown -R grid:oinstall /home/grid/.ssh


# Change permissions of the authorized_keys file for the grid user
RUN ["chmod", "0640", "/home/grid/.ssh/authorized_keys"]


# Generate SSH host ECDSA shared keys
RUN ssh-keygen -q -C '' -N '' -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key


# Create the ssh_known_hosts file
RUN for NODE in rac1 rac2; do (echo -n "$NODE " && cat /etc/ssh/ssh_host_ecdsa_key.pub) >> /etc/ssh/ssh_known_hosts; done


###################################################################################
##  Files and Directories
###################################################################################

# Create installation root directory
RUN ["mkdir", "-p", "/u01"]
RUN ["chgrp", "oinstall", "/u01"]
RUN ["chmod", "0775", "/u01"]


###################################################################################
##  Misc
###################################################################################

# Allow non-privileged users the ability to execute the ping command
RUN ["chmod", "4755", "/bin/ping"]


# SELinux bug fix
RUN ["mkdir", "-p", "/etc/selinux/targeted/contexts/"]
ADD ["dbus_contexts", "/etc/selinux/targeted/contexts/"]


# Hide/disable the ttyS0 serial console service
RUN ["systemctl", "mask", "serial-getty@ttyS0.service"]
