use it for all the publicly exposed apps through k8s ingress

how to use script for generating self-signed cert :

./ssl-wildcard.sh "desired domain name"

example:
./ssl-wildcard.sh tinotest.com

So now we have valid cert for shop.tinotest.com and also other subdomains like example.tinotest.com