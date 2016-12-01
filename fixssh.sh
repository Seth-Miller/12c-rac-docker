#!/bin/bash



FIXHOSTS=$@
ROOTKEYS=[]
GRIDKEYS=[]
ORACLEKEYS=[]
MYLOOP=0


for MYHOST in ${FIXHOSTS?}; do

  docker exec ${MYHOST?} sh -c "touch /etc/ssh/ssh_known_hosts && chmod 644 /etc/ssh/ssh_known_hosts" || \
    echo "Unable to generate ssh_known_hosts on ${MYHOST}"

  docker exec ${MYHOST?} sh -c "ssh-keyscan -t ecdsa ${FIXHOSTS?} >> /etc/ssh/ssh_known_hosts 2> /dev/null" || \
    echo "Unable to scan for known_hosts keys on ${MYHOST}"

  docker exec ${MYHOST?} sh -c "[[ -f ~/.ssh/id_rsa ]] || ssh-keygen -q -N '' -f ~/.ssh/id_rsa" || \
    echo "Unable to generate root SSH key on ${MYHOST}"

  ROOTKEYS[${MYLOOP?}]=$(docker exec ${MYHOST?} sh -c "cat ~/.ssh/id_rsa.pub") || \
    echo "Unable to get root key from ${MYHOST}"

  docker exec --user grid ${MYHOST?} sh -c "[[ -f ~/.ssh/id_rsa ]] || ssh-keygen -q -N '' -f ~/.ssh/id_rsa" || \
    echo "Unable to generate grid SSH key on ${MYHOST}"

  GRIDKEYS[${MYLOOP?}]=$(docker exec --user grid ${MYHOST?} sh -c "cat ~/.ssh/id_rsa.pub") || \
    echo "Unable to get grid key from ${MYHOST}"

  docker exec --user oracle ${MYHOST?} sh -c "[[ -f ~/.ssh/id_rsa ]] || ssh-keygen -q -N '' -f ~/.ssh/id_rsa" || \
    echo "Unable to generate oracle SSH key on ${MYHOST}"

  ORACLEKEYS[${MYLOOP?}]=$(docker exec --user oracle ${MYHOST?} sh -c "cat ~/.ssh/id_rsa.pub") || \
    echo "Unable to get oracle key from ${MYHOST}"

  let MYLOOP++

done


for MYHOST in ${FIXHOSTS?}; do

  for MYKEY in $(seq 1 ${#ROOTKEYS[@]}); do

    let MYKEY--

    docker exec ${MYHOST?} sh -c "echo ${ROOTKEYS[${MYKEY?}]} >> ~/.ssh/authorized_keys"

  done || echo "Unable to add root public SSH keys on ${MYHOST}"


  for MYKEY in $(seq 1 ${#GRIDKEYS[@]}); do

    let MYKEY--

    docker exec --user grid ${MYHOST?} sh -c "echo ${GRIDKEYS[${MYKEY?}]} >> ~/.ssh/authorized_keys"

  done || echo "Unable to add grid public SSH keys on ${MYHOST}"


  for MYKEY in $(seq 1 ${#ORACLEKEYS[@]}); do

    let MYKEY--

    docker exec --user oracle ${MYHOST?} sh -c "echo ${ORACLEKEYS[${MYKEY?}]} >> ~/.ssh/authorized_keys"

  done || echo "Unable to add oracle public SSH keys on ${MYHOST}"


    docker exec ${MYHOST?} sh -c "chmod 600 ~/.ssh/authorized_keys"

    docker exec --user grid ${MYHOST?} sh -c "chmod 600 ~/.ssh/authorized_keys"

    docker exec --user oracle ${MYHOST?} sh -c "chmod 600 ~/.ssh/authorized_keys"

done



