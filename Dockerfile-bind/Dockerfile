FROM sameersbn/bind:latest
MAINTAINER sethmiller.sm@gmail.com

# Generate keys for BIND utilities like nsupdate and rndc
RUN ["mkdir", "-p", "/etc/keys"]

RUN ["dnssec-keygen", "-K", "/etc/keys", "-a", "HMAC-MD5", "-b", "512", "-n", "USER", "-r", "/dev/urandom", "dnsupdate."]
