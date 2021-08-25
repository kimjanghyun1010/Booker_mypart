source {{ .common.directory.app }}/function.env

SITE_DNS=*.{{ .global.domain }}
CERT_PW=test
path="{{ .common.directory.app }}"

echo_create "{{ .global.domain }} Domain certs"
mkdir -p $path/certs
cd $path/certs

echo 01 > ca.srl

openssl genrsa \
   -des3 \
   -passout pass:${CERT_PW} \
   -out ca-key.pem 2048

openssl req -new \
   -x509 -days 3650 \
   -key ca-key.pem \
   -out ca.pem \
   -passin pass:${CERT_PW} \
   -subj "/C=KR/ST=Seoul/L=Gangnam/O=Crossent Inc./OU=Paasxpert/CN=${SITE_DNS}"

openssl genrsa \
   -des3 \
   -passout pass:${CERT_PW} \
   -out server-key.pem 2048

openssl req \
   -subj "/CN=${SITE_DNS}" \
   -passin pass:${CERT_PW} \
   -new -key server-key.pem \
   -out server.csr

printf "subjectAltName=DNS:${SITE_DNS},IP:127.0.0.1" \
| openssl x509 -req \
   -passin pass:${CERT_PW} \
   -extfile /dev/stdin \
   -days 3650 -in server.csr \
   -CA ca.pem -CAkey ca-key.pem \
   -out server-cert.pem

openssl rsa -passin pass:${CERT_PW} \
    -in server-key.pem -out server-key.pem

openssl verify -CAfile ca.pem server-cert.pem

cp $path/certs/server-cert.pem $path/certs/server.crt
cp $path/certs/server-cert.pem $path/certs/ca-certificates.crt
cp $path/certs/server-cert.pem $path/certs/cacerts.pem
ls $path/certs
