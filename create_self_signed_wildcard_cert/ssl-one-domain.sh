#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
  echo "Error: No domain name argument provided"
  echo "Usage: Provide a domain name as an argument"
  exit 1
fi

DOMAIN=$1

# Create root CA & Private key
openssl req -x509 \
            -sha256 -days 5550 \
            -nodes \
            -newkey rsa:2048 \
            -subj "/CN=${DOMAIN}/C=US/L=San Francisco" \
            -keyout rootCA.key -out rootCA.crt

# Generate Private key for the domain
openssl genrsa -out ${DOMAIN}.key 2048

# Create CSR config
cat > csr.conf <<EOF
[ req ]
default_md = sha256
prompt = no
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]
commonName = ${DOMAIN}
countryName = US
stateOrProvinceName = No state
localityName = City
organizationName = LTD

[v3_req]
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=critical,serverAuth,clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = www.${DOMAIN}

EOF

# Create CSR request using the private key
openssl req -new -nodes -key ${DOMAIN}.key -out ${DOMAIN}.csr -config csr.conf

# Create a certificate config (separate from csr.conf)
cat > cert.conf <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = www.${DOMAIN}

EOF

# Create SSL certificate signed with self-signed CA
openssl x509 -req \
    -in ${DOMAIN}.csr \
    -CA rootCA.crt -CAkey rootCA.key \
    -CAcreateserial -out ${DOMAIN}.crt \
    -days 5550 \
    -sha256 -extfile cert.conf

