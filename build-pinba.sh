#!/bin/bash
set -e

WORK_DIR=/tmp
JUDY_DIR=${WORK_DIR}/judy-${JUDY_VERSION}
APORTS_DIR=${WORK_DIR}/aports-${APORTS_VERSION}
PINBA_DIR=${WORK_DIR}/pinba_engine-RELEASE_${PINBA_VERSION//./_}

cd ${WORK_DIR}

echo
echo "--> Update packages"
apk add --update alpine-sdk mariadb-dev protobuf-dev libtool libevent-dev automake autoconf make sed

echo
echo "--> Download and unpack aports"
wget -O - https://github.com/alpinelinux/aports/archive/v${APORTS_VERSION}.tar.gz | tar -xzf -

echo
echo "--> Change MariaDB source mirror in aports"
sed -i "s#https\:\/\/downloads.mariadb.org\/interstitial\/#http\:\/\/ftp.hosteurope.de\/mirror\/archive.mariadb.org\/#" ${APORTS_DIR}/main/mariadb/APKBUILD

echo
echo "--> Download and unpack Pinba Engine v.${PINBA_VERSION}"
wget -O - https://github.com/tony2001/pinba_engine/archive/RELEASE_${PINBA_VERSION//./_}.tar.gz | tar -xzf -

echo
echo "--> Download and unpack Judy v.${JUDY_VERSION}"
wget -O - http://downloads.sourceforge.net/project/judy/judy/Judy-${JUDY_VERSION}/Judy-${JUDY_VERSION}.tar.gz | tar -xzf -

echo
echo "--> Compile and install Judy"
cd ${JUDY_DIR}
./configure
make install

echo
echo "--> Fetch, unpack and prepare MariaDB sources"
cd ${APORTS_DIR}/main/mariadb/
abuild -Fq fetch
abuild -Fq unpack
abuild -Fq prepare

MYSQL_SRC=$(ls -d ${APORTS_DIR}/main/mariadb/src/mariadb-*/)

echo
echo "--> Copy MySQL include"
cp -r /usr/include/mysql/* "${MYSQL_SRC}include/"

echo
echo "--> Compile and install Pinba Engine"
cd ${PINBA_DIR}
./buildconf.sh 
./configure --with-mysql="$MYSQL_SRC" --libdir=/usr/lib/mysql/plugin
make install

echo
echo "--> Enable Pinba Engine linbrary (pinba.ini)"
cat > /usr/lib/mysql/plugin/pinba.ini << EOF
#
# library binary file name (without .so or .dll)
# component_name
#
libpinba_engine
pinba
EOF

echo
echo "--> Clean up..."
rm -rf ${APORTS_DIR}
rm -rf ${JUDY_DIR}
rm -rf ${WORK_DIR}/pinba_engine-*

apk del alpine-sdk 
apk del autoconf
apk del automake
apk del libtool
apk del libevent-dev
apk del make
apk del mariadb-dev 
apk del protobuf-dev 

rm -rf /var/cache/apk/*
rm -rf /var/cache/distfiles/*
