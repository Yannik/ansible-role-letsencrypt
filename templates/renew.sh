#!/bin/bash
cd {{ letsencrypt_dir }}/{{ item.name }}
python ../acme-tiny/acme_tiny.py --account-key account.key --csr domain.csr --acme-dir {{ letsencrypt_challenge_dir }} > signed.crt
cat signed.crt ../lets-encrypt-x3-cross-signed.pem > chained.crt

if [ -s /etc/init.d/apache2 ]; then
    /etc/init.d/apache2 reload
fi
