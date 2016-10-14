FROM oraclelinux:7.2
MAINTAINER sethmiller.sm@gmail.com


# Passwords for grid and oracle users
ENV ["GRID_PASSWORD", "oracle_4U"]
ENV ["ORACLE_PASSWORD", "oracle_4U"]


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


# Add groups for grid infrastructure
RUN ["groupadd", "--gid", "54421", "asmdba"]
RUN ["groupadd", "--gid", "54422", "asmadmin"]


# Add grid infrastructure owner
RUN ["useradd", "--create-home", "--uid", "54421", "--gid", "oinstall", "--groups", "dba,asmdba,asmadmin", "grid"]


# Give grid and oracle users passwords
RUN ["echo", "grid:${GRID_PASSWORD}", "|", "chpasswd"]
RUN ["echo", "oracle:${ORACLE_PASSWORD}", "|", "chpasswd"]


# Add ulimits configuration file for grid user
# oracle user ulimits configuration file already added by oracle-rdbms-server-12cR1-preinstall
ADD ["grid_security_limits.conf", "/etc/security/limits.conf.d/"]


# Create installation root directory
RUN ["mkdir", "-p", "/u01"]
RUN ["chgrp", "oinstall", "/u01"]
RUN ["chmod", "0775", "/u01"]


# Allow non-privileged users the ability to execute the ping command
RUN ["chmod", "4755", "/bin/ping"]


# SELinux bug fix
RUN ["echo", "'<busconfig><selinux></selinux></busconfig>'", "> /etc/selinux/targeted/contexts/dbus_contexts"]
