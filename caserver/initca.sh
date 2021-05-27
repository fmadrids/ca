#!/bin/bash

[[ $# -eq 1 || $# -eq 0 ]] || exit 1
base_dir=$(dirname $(readlink -f $0))

[ -f ${base_dir}/ca.conf ] || exit 1
. ${base_dir}/ca.conf
export carootdir

if [ ! -z $1 ]
then
    intermediate=$1
else
    intermediate=intermediate01
fi

echo
echo "#################################"
echo "Creating CA structure"
echo "#################################"
echo
mkdir ${carootdir}/{certs,crl,newcerts,private,jks}
chmod 700 ${carootdir}/private
touch ${carootdir}/index.txt
echo 1000 > ${carootdir}/serial
cp ${base_dir}/openssl.cnf ${carootdir}

echo
echo "#################################"
echo "Generating CA key"
echo "#################################"
echo
openssl genrsa -aes256 -out ${carootdir}/private/ca.key.pem 4096
chmod 400 ${carootdir}/private/ca.key.pem

echo
echo "#################################"
echo "Generating CA cert"
echo "#################################"
echo
openssl req -config ${carootdir}/openssl.cnf -key ${carootdir}/private/ca.key.pem -new -x509 -days ${ca_expiry_days} -sha256 -extensions v3_ca -out ${carootdir}/certs/ca.cert.pem
chmod 444 ${carootdir}/certs/ca.cert.pem

echo
echo "#################################"
echo "Generating CA key"
echo "#################################"
echo
openssl x509 -noout -text -in ${carootdir}/certs/ca.cert.pem

mkdir ${interrootdir}
${base_dir}/create_intermediate.sh "${intermediate}"
