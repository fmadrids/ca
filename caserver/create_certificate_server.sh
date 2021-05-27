#!/bin/bash

[ $# -eq 2 ] || exit 1
base_dir=$(dirname $(readlink -f $0))

[ -f ${base_dir}/ca.conf ] || exit 1
. ${base_dir}/ca.conf
export carootdir
export interrootdir

intername=$1
url=$2
interdir=${interrootdir}/${intername}
[ -d ${interdir} ] || exit 1
export interdir

SAN="DNS:${url}"
echo "Please enter additional Subject Alternative Names (SAN) or enter to finish:"
read dns
while [ ! -z ${dns} ]
do
   SAN="${SAN},DNS:${dns}"
   read dns
done

echo "Please enter IP addresses or enter to finish:"
read ip 
while [ ! -z ${ip} ]
do
   IP="${IP},IP:${ip}"
   read ip
done
[ -n ${ip} ] && SAN="${SAN}${IP}"
export SAN

# Create key
echo
echo "#########################################"
echo "Creating the server key" 
echo "#########################################"
echo
openssl genrsa -aes256 -out ${interdir}/private/${url}.server.key.pem 2048
chmod 400 ${interdir}/private/${url}.server.key.pem

# Create certificate
echo
echo "#########################################"
echo "Creating the server request"
echo "#########################################"
echo
openssl req -config ${interdir}/openssl.cnf -key ${interdir}/private/${url}.server.key.pem -new -sha256 -out ${interdir}/csr/${url}.server.csr.pem
echo
echo "#########################################"
echo "Intermediate CA signs the request"
echo "#########################################"
echo
openssl ca -config ${interdir}/openssl.cnf -extensions server_cert -days 375 -notext -md sha256 -in ${interdir}/csr/${url}.server.csr.pem -out ${interdir}/certs/${url}.server.cert.pem
chmod 444 ${interdir}/certs/${url}.server.cert.pem

# Verify certificate
echo
echo "#########################################"
echo "Verifying server certificate"
echo "#########################################"
echo
openssl x509 -noout -text -in ${interdir}/certs/${url}.server.cert.pem
openssl verify -CAfile ${interdir}/certs/ca-chain.cert.pem ${interdir}/certs/${url}.server.cert.pem
