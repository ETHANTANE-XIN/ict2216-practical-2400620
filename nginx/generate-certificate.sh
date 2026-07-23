#!/bin/sh
set -eu

if [ ! -s /certs/server.crt ] || [ ! -s /certs/server.key ]; then
  openssl req \
    -x509 \
    -nodes \
    -newkey rsa:2048 \
    -sha256 \
    -days 365 \
    -keyout /certs/server.key \
    -out /certs/server.crt \
    -subj "/CN=127.0.0.1" \
    -addext "subjectAltName=IP:127.0.0.1"
  chmod 0600 /certs/server.key
  chmod 0644 /certs/server.crt
fi
