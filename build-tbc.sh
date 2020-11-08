#!/bin/bash

echo "Start building TBC"

# find script directory
DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
MANGOS_DIR="${DIR}/mangos-tbc"
DATABASE_DIR="${DIR}/db-tbc"

# find mangos hash
cd MANGOS_DIR
MANGOS_HASH=$(git ls-tree --abbrev=8 HEAD mangos-tbc/ | grep -oP "commit \K\w+")
echo "The current mangos-tbc Hash is: ${MANGOS_HASH}"
# find database hash
cd DATABASE_DIR
DATABASE_HASH=$(git ls-tree --abbrev=8 HEAD db-tbc/ | grep -oP "commit \K\w+")
echo "The current db-tbc Hash is: ${DATABASE_HASH}"

# find build & run dir
BUILD_DIR="${DIR}/build-tbc/mangos-${MANGOS_HASH}_db-${DATABASE_HASH}"
RUN_DIR="${DIR}/run-tbc/mangos-${MANGOS_HASH}_db-${DATABASE_HASH}"

# die on directory exists
#[ -d "${BUILD_DIR}" ] && echo "Error: Build Directory ${BUILD_DIR} already exists - stopping build." && exit 1
#[ -d "${RUN_DIR}" ] && echo "Error: Run Directory ${RUN_DIR} already exists - stopping build." && exit 1

# makedir in build, logs & run
mkdir $BUILD_DIR
mkdir $BUILD_DIR/logs
mkdir $RUN_DIR

# cd BUILD_DIR
cd $BUILD_DIR

# build  
(cmake clear | tee $BUILD_DIR/logs/cmake.log) 3>&1 1>&2 2>&3 | tee $BUILD_DIR/logs/cmake.error.log
(cmake $MANGOS_DIR \
    -DCMAKE_INSTALL_PREFIX=$RUN_DIR \
    -DPCH=1 \
    -DDEBUG=0 \
    -DWARNINGS=1 \
    -DPOSTGRESQL=0 \
    -DBUILD_GAME_SERVER=ON \
    -DBUILD_LOGIN_SERVER=ON \
    -DBUILD_EXTRACTORS=ON \
    -DBUILD_SCRIPTDEV=ON \
    -DBUILD_PLAYERBOT=ON \
    -DBUILD_AHBOT=ON \
    -DBUILD_RECASTDEMOMOD=ON \
    -DBUILD_GIT_ID=ON \
    -DBUILD_DOCS=OFF \
    | tee $BUILD_DIR/logs/cmake.log) 3>&1 1>&2 2>&3 | tee $BUILD_DIR/logs/cmake.error.log
    
(make | tee $BUILD_DIR/logs/make.log) 3>&1 1>&2 2>&3 | tee $BUILD_DIR/logs/make.error.log
(make install | tee $BUILD_DIR/logs/make.log) 3>&1 1>&2 2>&3 | tee $BUILD_DIR/logs/make.error.log

# create symlinks for executables
REALMD_LINK="${DIR}/run-tbc/realmd"
MANGOSD_LINK="${DIR}/run-tbc/mangosd"
ln -s -f $RUN_DIR/bin/realmd $REALMD_LINK
ln -s -f $RUN_DIR/bin/mangosd $MANGOSD_LINK

# create symlinks for configs
CONFIG_DIR="${DIR}/config-tbc/"
ln -s -f $CONFIG_DIR/ahbot.conf $RUN_DIR/etc/ahbot.conf
ln -s -f $CONFIG_DIR/mangosd.conf $RUN_DIR/etc/mangosd.conf
ln -s -f $CONFIG_DIR/playerbot.conf $RUN_DIR/etc/playerbot.conf
ln -s -f $CONFIG_DIR/realmd.conf $RUN_DIR/etc/realmd.conf