#!/bin/bash

[ $# -eq 2 ] || exit 1
base_dir=$(dirname $(readlink -f $0))

[ -f ${base_dir}/ca.conf ] || exit 1
. ${base_dir}/ca.conf
export carootdir
export interrootdir

intername=$1
name=$2
interdir=${interrootdir}/${intername}
[ -d ${interdir} ] || exit 1
export interdir

SAN="DNS:none"
export SAN

# Create key
echo
echo "#########################################"
echo "Creating the user key" 
echo "#########################################"
echo
openssl genrsa -aes256 -out ${interdir}/private/${name}.client.key.pem 2048
chmod 400 ${interdir}/private/${name}.client.key.pem

# Create certificate
echo
echo "#########################################"
echo "Creating the user request"
echo "#########################################"
echo
openssl req -config ${interdir}/openssl.cnf -key ${interdir}/private/${name}.client.key.pem -new -sha256 -out ${interdir}/csr/${name}.client.csr.pem
echo
echo "#########################################"
echo "Intermediate CA signs the request"
echo "#########################################"
echo
openssl ca -config ${interdir}/openssl.cnf -extensions usr_cert -days 375 -notext -md sha256 -in ${interdir}/csr/${name}.client.csr.pem -out ${interdir}/certs/${name}.client.cert.pem
chmod 444 ${interdir}/certs/${name}.client.cert.pem

# Verify certificate
echo
echo "#########################################"
echo "Verifying user certificate"
echo "#########################################"
echo
openssl x509 -noout -text -in ${interdir}/certs/${name}.client.cert.pem
openssl verify -CAfile ${interdir}/certs/ca-chain.cert.pem ${interdir}/certs/${name}.client.cert.pem
