#!/bin/bash

[ $# -eq 3 ] || exit 1
base_dir=$(dirname $(readlink -f $0))

[ -f ${base_dir}/ca.conf ] || exit 1
. ${base_dir}/ca.conf
export carootdir
export interrootdir

intername=$1
url=$2
purpose=$3

interdir=${interrootdir}/${intername}
[ -d ${interdir} ] || exit 1
export interdir
jksdir=${carootdir}/jks
[ -d ${jksdir} ] || exit 1
export jksdir

# Create truststore with CA and intermediate
echo
echo "#########################################"
echo "Creating the truststore" 
echo "#########################################"
echo
keytool -import -alias CAroot -file ${carootdir}/certs/ca.cert.pem -keystore ${jksdir}/${url}.truststore.jks -deststoretype pkcs12
keytool -import -alias CAintermediate -file ${interdir}/certs/${intername}.cert.pem -keystore ${jksdir}/${url}.truststore.jks -deststoretype pkcs12

# This intermediate step is the only way to import a private key to a Java JKS keystore
echo
echo "#########################################"
echo "Converting to PKCS12"
echo "#########################################"
echo
openssl pkcs12 -export -inkey ${interdir}/private/${url}.${purpose}.key.pem -in ${interdir}/certs/${url}.${purpose}.cert.pem -chain -CAfile ${interdir}/certs/ca-chain.cert.pem -name ${url} -out ${jksdir}/${url}.${purpose}.p12

# Import the intermediate PKCS12 to a Java JKS keystore
echo
echo "#########################################"
echo "Creating the JKS keystore" 
echo "#########################################"
echo
keytool -import -trustcacerts -alias CAroot -file ${carootdir}/certs/ca.cert.pem -keystore ${jksdir}/${url}.${purpose}.keystore.jks -deststoretype pkcs12
keytool -importkeystore -srckeystore ${jksdir}/${url}.${purpose}.p12 -srcstoretype pkcs12 -destkeystore ${jksdir}/${url}.${purpose}.keystore.jks -deststoretype pkcs12

# Verify keystore
echo
echo "#########################################"
echo "Verifying Java JKS keystore"
echo "#########################################"
echo
keytool -list -keystore ${jksdir}/${url}.${purpose}.keystore.jks
