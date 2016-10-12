#!/bin/bash
set -e


KEYS_DATA_DIR=${KEYS_DIR?}

create_bind_key_dir() {
  mkdir -p ${KEYS_DATA_DIR?}
  chmod -R 0775 ${KEYS_DATA_DIR?}
  chown -R ${BIND_USER}:${BIND_USER} ${KEYS_DATA_DIR?}

  # move keys into new keys directory
  if [ ! -d ${KEYS_DATA_DIR?}/keys ]; then
    mv /etc/keys ${KEYS_DATA_DIR?}/keys
  fi
  rm -rf /etc/keys
}


create_bind_key_dir
