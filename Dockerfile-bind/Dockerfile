FROM sameersbn/bind:latest
MAINTAINER sethmiller.sm@gmail.com


ENV ["KEYS_DIR", "/bindauth"]


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


# Add supplemental entrypoint
COPY ["entrypoint_supplemental", "/etc/"]


# Modify the original entrypoint.sh to include the supplemental
RUN echo "source /etc/entrypoint_supplemental" >> /sbin/entrypoint.sh
RUN echo "create_bind_key_dir" >> /sbin/entrypoint.sh


# Expose the keys
VOLUME ["/etc/keys"]
