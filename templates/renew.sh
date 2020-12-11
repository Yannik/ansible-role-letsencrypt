#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o errtrace
set -o nounset

function cleanup {
    # https://stackoverflow.com/questions/5719030/bash-silently-kill-background-function-process
    for x in $(pgrep -f "python3 -m http.server 80" || true); do
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

# do nothing if certificate is valid for more than 31 days (31*24*60*60)
[[ -s signed.crt && ! -f "force" ]] && openssl x509 -noout -in signed.crt -checkend 2678400 > /dev/null && exit
rm -f force

{% if item.challenge|default('http-01') == 'http-01' %}
if ! lsof -i:80 > /dev/null; then
    mkdir -p serve/.well-known
    ln -sf "{{ letsencrypt_challenge_dir }}" serve/.well-known/acme-challenge
    cd serve
    python3 -m http.server 80 > /dev/null &
    cd ..
fi
{% endif %}

../dehydrated/dehydrated --cron --config dehydrated.conf \
    --alias {{ item.name }} \
    {% for subdomain in item.subdomains|selectattr('name', 'defined') %}--domain {{ subdomain.name }} {% endfor %} \
    {% for subdomain in item.subdomains|selectattr('name', 'undefined') %}--domain {{ subdomain }} {% endfor %} \
    --hook ./multihook.sh \
    --algo {{ item.key_algo|default(letsencrypt_key_algo) }} \
    --challenge {{ item.challenge|default('http-01') }}

cp certs/{{ item.name }}/cert.pem signed.crt
cp certs/{{ item.name }}/privkey.pem domain.key
cat signed.crt ../lets-encrypt-r3.pem > chained.crt
cat chained.crt domain.key > chained_cert+key.pem

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
