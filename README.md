[![Build Status](https://travis-ci.org/Yannik/ansible-role-letsencrypt.svg?branch=master)](https://travis-ci.org/Yannik/ansible-role-letsencrypt)

ansible needs to be installed on the remote host for restarting services

At some point, I might replace dehydrated with acme.sh because of the superior [hook features](https://github.com/acmesh-official/acme.sh/wiki/Using-'--pre-hook',--'--post-hook',-'---renew-hook'-and-'---reloadcmd') and it's integrated [DNS api client scripts](https://github.com/acmesh-official/acme.sh/wiki/dnsapi) and [deploy hooks](https://github.com/acmesh-official/acme.sh/wiki/deployhooks).
