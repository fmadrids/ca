#!/bin/bash

# Format of the bulk file:
# URL#PASSWORD#SAN (p.e.: DNS:test02.labs.paradigma.com,DNS:test...)#PURPOSE
pattern='^([\.[:alnum:]]+)#([_[:alnum:]]+)#(DNS:([\.:,[:alnum:]]+))*#([[:alpha:]]+)$'

[ $# -eq 2 ] || exit 1
base_dir=$(dirname $(readlink -f $0))

[ -f ${base_dir}/ca.conf ] || exit 1
. ${base_dir}/ca.conf
export carootdir
export interrootdir

intername=$1
bulkfile=$2
interdir=${interrootdir}/${intername}
[ -d ${interdir} ] || exit 1
export interdir
[ -f ${bulkfile} ] || exit 1

echo "Please enter the Intermediate password:"
read ca_password

while read -r line
do
  [[ ${line} =~ ${pattern} ]]
  if [ $? -eq 0 ]; then
    url=${BASH_REMATCH[1]}
    password=${BASH_REMATCH[2]}
    san=${BASH_REMATCH[3]}
    purpose=${BASH_REMATCH[5]}
  else
     exit 1
  fi
  echo "Generating ${url} certificate"

  if [ -n "${san}" ]; then
    SAN="DNS:${url},${san}"
  else
    SAN="DNS:${url}"
  fi
  export SAN

  case $purpose in
    "client")
      extension="usr_cert"
      ;;
    "server") 
      extension="server_cert"
      ;;
    "both") 
      extension="both_cert"
      ;;
    *) 
      exit 1
      ;;
  esac

  # Create key
  openssl genrsa -aes256 -passout pass:${password} -out ${interdir}/private/${url}.${purpose}.key.pem 2048 >/dev/null 2>&1
  [ $? = 0 ] || exit 1
  chmod 400 ${interdir}/private/${url}.${purpose}.key.pem

  # Create certificate
  openssl req -batch -config ${interdir}/openssl.cnf -passin pass:${password} -passout pass:${password} -key ${interdir}/private/${url}.${purpose}.key.pem -new -sha256 -out ${interdir}/csr/${url}.${purpose}.csr.pem >/dev/null 2>&1
  [ $? = 0 ] || exit 1
  openssl ca -batch -config ${interdir}/openssl.cnf -subj "/C=ES/ST=Madrid/L=Pozuelo/O=Paradigma/OU=Sistemas/CN=${url}/emailAddress=asistemas@paradigma.com" -passin pass:${ca_password} -extensions ${extension} -days 375 -notext -md sha256 -in ${interdir}/csr/${url}.${purpose}.csr.pem -out ${interdir}/certs/${url}.${purpose}.cert.pem >/dev/null 2>&1
  [ $? = 0 ] || exit 1
  chmod 444 ${interdir}/certs/${url}.${purpose}.cert.pem

done < ${bulkfile}
