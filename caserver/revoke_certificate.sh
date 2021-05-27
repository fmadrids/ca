#!/bin/bash

[ $# -eq 2 ] || exit 1
base_dir=$(dirname $(readlink -f $0))

[ -f ${base_dir}/ca.conf ] || exit 1
. ${base_dir}/ca.conf
export carootdir
export interrootdir

intername=$1
#File must be in certs directory with a name ...cert.pem
filename=$2
interdir=${interrootdir}/${intername}
[ -d ${interdir} ] || exit 1
export interdir
filepath=${interdir}/certs/${filename}
[ -f ${filepath} ] || exit 1

SAN="DNS:none"
export SAN

# Revoke certificate
echo
echo "#########################################"
echo "Revoking certificate"
echo "#########################################"
echo
openssl ca -config ${interdir}/openssl.cnf -revoke ${filepath}

# Delete files
echo
echo "#########################################"
echo "Deleting certificate files"
echo "#########################################"
echo
basicname=${filename%.cert.pem}
rm -f ${interdir}/certs/${basicname}.cert.pem
rm -f ${interdir}/private/${basicname}.key.pem
