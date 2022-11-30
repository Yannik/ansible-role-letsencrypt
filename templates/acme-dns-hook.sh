#!/bin/sh

SERVER="{{ letsencrypt_acme_dns_server }}"
ACTION=$1
DOMAIN=$2
TOKEN=$4

case "$ACTION" in
    "deploy_challenge")
	case "$DOMAIN" in
{% for subdomain in item.subdomains|selectattr('acme_domain_id', 'defined') %}
            "{{ subdomain.name|regex_replace('^\\*\\.', '') }}")
                result=$(curl --silent -X POST \
                  -H "X-Api-User: {{ subdomain.acme_user }}" \
                  -H "X-Api-Key: {{ subdomain.acme_pass }}" \
                  -d "{\"subdomain\": \"{{ subdomain.acme_domain_id }}\", \"txt\": \"$TOKEN\"}" \
                  $SERVER/update)
		if echo $result | jq -e '.error' > /dev/null; then
		    echo "Error: $result"
		    exit 1
		fi
            ;;
{% endfor %}
{% if 'acme_domain_id' in item %}
            *)
                result=$(curl --silent -X POST \
                  -H "X-Api-User: {{ item.acme_user }}" \
                  -H "X-Api-Key: {{ item.acme_pass }}" \
                  -d "{\"subdomain\": \"{{ item.acme_domain_id }}\", \"txt\": \"$TOKEN\"}" \
                  $SERVER/update)
		if echo $result | jq -e '.error' > /dev/null; then
		    echo "Error: $result"
		    exit 1
		fi
            ;;
{% endif %}
        esac
        ;;
    "clean_challenge")
	case "$DOMAIN" in
{% for subdomain in item.subdomains|selectattr('acme_domain_id', 'defined') %}
            "{{ subdomain.name|regex_replace('^\\*\\.', '') }}")
                result=$(curl --silent -X POST \
                  -H "X-Api-User: {{ subdomain.acme_user }}" \
                  -H "X-Api-Key: {{ subdomain.acme_pass }}" \
                  -d "{\"subdomain\": \"{{ subdomain.acme_domain_id }}\", \"txt\": \"$TOKEN\"}" \
                  $SERVER/delete)
		if echo $result | jq -e '.error' > /dev/null; then
		    echo "Error: $result"
		    exit 1
		fi
            ;;
{% endfor %}
{% if 'acme_domain_id' in item %}
            *)
                result=$(curl --silent -X POST \
                  -H "X-Api-User: {{ item.acme_user }}" \
                  -H "X-Api-Key: {{ item.acme_pass }}" \
                  -d "{\"subdomain\": \"{{ item.acme_domain_id }}\", \"txt\": \"$TOKEN\"}" \
                  $SERVER/delete)
		if echo $result | jq -e '.error' > /dev/null; then
		    echo "Error: $result"
		    exit 1
		fi
            ;;
{% endif %}
        esac
        ;;
    "deploy_cert")
        # optional:
        # /path/to/deploy_cert.sh "$@"
        ;;
    "unchanged_cert")
        ;;
    "startup_hook")
        ;;
    "exit_hook")
        ;;
esac

