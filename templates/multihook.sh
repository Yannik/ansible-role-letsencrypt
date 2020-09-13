#!/usr/bin/env bash
{% if item.subdomains|selectattr('acme_domain_id', 'defined')|list|length > 0 %}
./acme-dns-hook.sh "$@"
{% endif %}
{% for hook in item.hooks|default([]) %}
../hooks/{{ hook }} "$@"
{% endfor %}
