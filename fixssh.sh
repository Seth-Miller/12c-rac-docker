#!/bin/sh



FIXHOSTS=$@


for MYHOST in ${FIXHOSTS?}; do

  docker exec ${MYHOST?} "touch /etc/ssh/ssh_known_hosts && chmod 644 /etc/ssh/ssh_known_hosts"

  docker exec ${MYHOST?} ssh-keyscan -t ecdsa ${FIXHOSTS?} | xargs -I MYKEY docker exec ${MYHOST?} sed -i '$a'MYKEY /etc/ssh/ssh_known_hosts

done
