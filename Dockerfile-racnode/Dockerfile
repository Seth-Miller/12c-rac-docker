FROM oraclelinux:7.2
MAINTAINER sethmiller.sm@gmail.com


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

RUN ["groupadd", "--gid", "54421", "asmdba"]

RUN ["groupadd", "--gid", "54422", "asmadmin"]

RUN ["useradd", "--create-home", "--uid", "54421", "--gid", "oinstall", "--groups", "dba,asmdba,asmadmin", "grid"]

RUN ["echo", "oracle:oracle_4U", "|", "chpasswd"]

RUN ["echo", "grid:oracle_4U", "|", "chpasswd"]

ADD ["grid_security_limits.conf", "/etc/security/limits.conf.d/"]

RUN ["mkdir", "-p", "/u01"]

RUN ["chgrp", "oinstall", "/u01"]

RUN ["chmod", "0775", "/u01"]

RUN ["chmod", "4755", "/bin/ping"]

RUN ["mkdir", "-p", "/etc/selinux/targeted/contexts/"]

RUN ["echo", "'<busconfig><selinux></selinux></busconfig>'", "> /etc/selinux/targeted/contexts/dbus_contexts"]
