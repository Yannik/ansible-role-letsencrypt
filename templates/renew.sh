#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o errtrace
set -o nounset

function cleanup {
    # https://stackoverflow.com/questions/5719030/bash-silently-kill-background-function-process
    for x in $(pgrep -f "python3 {{ letsencrypt_dir }}/HTTPServer.py" || true); do
        kill $x
        wait $x 2>/dev/null || true
    done
    rm -rf serve
}
function handle_error {
    >&2 echo "An error occured!"
    cleanup
    exit 1
}

trap handle_error ERR

cd {{ letsencrypt_dir }}/{{ item.name }}

force=""
[[ -f "force" ]] && force="--force" && rm -f force

{% if item.challenge|default('http-01') == 'http-01' %}
if ! lsof -i:80 > /dev/null; then
    mkdir -p serve/.well-known
    ln -sf "{{ letsencrypt_challenge_dir }}" serve/.well-known/acme-challenge
    cd serve
    python3 "{{ letsencrypt_dir }}/HTTPServer.py" &
    cd ..
fi
{% endif %}

../dehydrated/dehydrated --cron --config dehydrated.conf \
    --alias {{ item.name }} \
    {% for subdomain in item.subdomains|selectattr('name', 'defined') %}--domain {{ subdomain.name }} {% endfor %} \
    {% for subdomain in item.subdomains|selectattr('name', 'undefined') %}--domain {{ subdomain }} {% endfor %} \
    --hook ./multihook.sh \
    --algo {{ item.key_algo|default(letsencrypt_key_algo) }} \
    --challenge {{ item.challenge|default('http-01') }} $force

cp certs/{{ item.name }}/cert.pem signed.crt
cp certs/{{ item.name }}/privkey.pem domain.key
cp certs/{{ item.name }}/chain.pem chain.pem
cp certs/{{ item.name }}/fullchain.pem fullchain.pem
cat signed.crt chain.pem > chained.crt
cat chained.crt domain.key > chained_cert+key.pem

{% if item.user is defined %}
chown -R {{ item.user }} certs signed.crt domain.key chained.crt chain.pem fullchain.pem chained_cert+key.pem
{% endif %}
{% if item.group is defined %}
chgrp -R {{ item.user }} certs signed.crt domain.key chained.crt chain.pem fullchain.pem chained_cert+key.pem
{% endif %}

if [ -s /etc/init.d/apache2 ]; then
    systemctl reload apache2 || true
fi

if [ -s /etc/init.d/dovecot ]; then
    systemctl reload dovecot || true
fi

if [ -s /etc/init.d/postfix ]; then
    systemctl reload postfix || true
fi

if [ -s /etc/init.d/lighttpd ]; then
    systemctl restart lighttpd || true
fi

cleanup
