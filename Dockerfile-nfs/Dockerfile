FROM oraclelinux:7.2
MAINTAINER sethmiller.sm@gmail.com


# Update the operating system
RUN ["yum", "-y", "update"]


# Add the YUM repositories
ADD ["http://public-yum.oracle.com/public-yum-ol7.repo", "/etc/yum.repos.d/"]
RUN ["rpm", "--install", "https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"]


# Download and import the gpg key
ADD ["http://public-yum.oracle.com/RPM-GPG-KEY-oracle-ol7", "/etc/yum.repos.d/"]
RUN ["rpm", "--import", "/etc/yum.repos.d/RPM-GPG-KEY-oracle-ol7"]


# Install necessary packages
RUN ["yum", "-y", "install", "nfs-ganesha-vfs"]


# Clean the yum cache
RUN ["yum", "clean", "all"]


# Create dbus directory
RUN ["mkdir", "-p", "/var/run/dbus"]


# Add the entrypoint script
ADD ["entrypoint.sh", "/"]


# Start the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
