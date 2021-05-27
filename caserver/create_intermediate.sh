#!/bin/bash

[ $# -eq 1 ] || exit 1
base_dir=$(dirname $(readlink -f $0))

[ -f ${base_dir}/ca.conf ] || exit 1
. ${base_dir}/ca.conf
export carootdir
export interrootdir

intername=$1
interdir=${interrootdir}/${intername}
export interdir
export SAN=""

echo
echo "#################################"
echo "Creating intermediate CA structure"
echo "#################################"
echo
mkdir ${interdir}
mkdir ${interdir}/{certs,crl,csr,newcerts,private}
chmod 700 ${interdir}/private
touch ${interdir}/index.txt
echo 1000 > ${interdir}/serial
echo 1000 > ${interdir}/crlnumber
sed "s/intermediate\./${intername}\./" ${base_dir}/openssl_intermediate.cnf >${interdir}/openssl.cnf

echo
echo "#################################"
echo "Creating intermediate CA key"
echo "#################################"
echo
openssl genrsa -aes256 -out ${interdir}/private/${intername}.key.pem 4096
chmod 400 ${interdir}/private/${intername}.key.pem

echo
echo "#################################"
echo "Creating intermediate CA request"
echo "#################################"
echo
openssl req -config ${interdir}/openssl.cnf -new -sha256 -key ${interdir}/private/${intername}.key.pem -out ${interdir}/csr/${intername}.csr.pem

echo
echo "#################################"
echo "Signing intermediate CA request"
echo "#################################"
echo
openssl ca -config ${carootdir}/openssl.cnf -extensions v3_intermediate_ca -days ${inter_expiry_days} -notext -md sha256 -in ${interdir}/csr/${intername}.csr.pem -out ${interdir}/certs/${intername}.cert.pem
chmod 444 ${interdir}/certs/${intername}.cert.pem

echo
echo "#################################"
echo "Verifying intermediate CA certificate"
echo "#################################"
echo
openssl x509 -noout -text -in ${interdir}/certs/${intername}.cert.pem
openssl verify -CAfile ${carootdir}/certs/ca.cert.pem ${interdir}/certs/${intername}.cert.pem

echo
echo "#################################"
echo "Creating certificate chain file"
echo "#################################"
echo
cat ${interdir}/certs/${intername}.cert.pem ${carootdir}/certs/ca.cert.pem > ${interdir}/certs/ca-chain.cert.pem
chmod 444 ${interdir}/certs/ca-chain.cert.pem
