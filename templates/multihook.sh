#!/usr/bin/env bash
{% if item.subdomains|selectattr('acme_domain_id', 'defined')|list|length > 0 or 'acme_domain_id' in item %}
./acme-dns-hook.sh "$@"
{% endif %}
{% for hook in item.hooks|default([]) %}
../hooks/{{ hook }} "$@"
{% endfor %}
