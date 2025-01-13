
use this branch for generating our own self-signed crt.

Then use that crt for all the publicly exposed apps through k8s ingress

how to use script for generating self-signed cert :

./create_self_signed_wildcard_cert/ssl-wildcard.sh "desired domain name"

example:
./create_self_signed_wildcard_cert/ssl-wildcard.sh "tinotest.com"


then put crt and key files into appropriate vault for example here:
v2.25.1/clients/tino-prod/group_vars/custom_vars/ssl-vault.yml


Now we have valid cert for shop.tinotest.com and also other subdomains like example.tinotest.com
