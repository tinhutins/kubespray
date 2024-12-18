#! /bin/bash

if [ "$#" -ne 1 ]
then
  echo "Error: No domain name argument provided"
  echo "Usage: Provide a domain name as an argument"
  exit 1
fi

DOMAIN=$1

# Create root CA & Private key

openssl req -x509 \
            -sha256 -days 3560 \
            -nodes \
            -newkey rsa:2048 \
            -subj "/CN=*.${DOMAIN}/C=US/L=San Fransisco" \
            -keyout rootCA.key -out rootCA.crt

# Generate Private key

openssl genrsa -out ${DOMAIN}.key 2048

# Create csr conf

cat > csr.conf <<EOF
[ req ]
default_md = sha256
prompt = no
req_extensions = req_ext
distinguished_name = req_distinguished_name

[req_distinguished_name]
commonName = *.${DOMAIN}
countryName = US
stateOrProvinceName = No state
localityName = City
organizationName = LTD

[req_ext]
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=critical,serverAuth,clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = *.${DOMAIN}

EOF

# create CSR request using private key

openssl req -new -nodes -key ${DOMAIN}.key -out ${DOMAIN}.csr -config csr.conf

# Create a external config file for the certificate

cat > cert.conf <<EOF

authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = *.${DOMAIN}

EOF

# Create SSl with self signed CA

openssl x509 -req \
    -in ${DOMAIN}.csr \
    -CA rootCA.crt -CAkey rootCA.key \
    -CAcreateserial -out ${DOMAIN}.crt \
    -days 3650 \
    -sha256 -extfile csr.conf -extensions req_ext