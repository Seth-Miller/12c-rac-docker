FROM sethmiller/bind:latest
MAINTAINER sethmiller.sm@gmail.com


RUN ["mkdir", "-p", "/etc/keys"]


# Generate keys for BIND utilities like nsupdate and rndc
RUN ["dnssec-keygen", \
        "-K", "/etc/keys", \
        "-a", "HMAC-MD5", \
        "-b", "512", \
        "-n", "USER", \
        "-r", "/dev/urandom", \
        "dnsupdate."]


# Config file for keys
COPY ["keys.conf", "/etc/bind/"]


# Add the key generated above to /etc/bind/keys.conf
RUN SECRET_KEY=$(grep '^Key:' /etc/keys/Kdnsupdate.*.private | awk '{print $2}') \
      && sed -i 's!REPLACE_WITH_SECRET_KEY!'${SECRET_KEY?}'!' /etc/bind/keys.conf


# Config file for zones
COPY ["named.conf.custom-zones", "/etc/bind/"]


# Database files
COPY ["db.example.com", "/etc/bind/"]
COPY ["db.10.10.10", "/etc/bind/"]
COPY ["db.11.11.11", "/etc/bind/"]


# Overwrite named.conf to include keys.conf and named.conf.custom-zones
COPY ["named.conf", "/etc/bind/"]


# Copy the key files
RUN cp /etc/keys/Kdnsupdate.* /etc/bind/
