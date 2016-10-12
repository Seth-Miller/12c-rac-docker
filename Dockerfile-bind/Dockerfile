FROM sameersbn/bind:latest
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
