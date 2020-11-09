#!/bin/bash

echo "[Build] Start building"

# find script directory
DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
MANGOS_DIR="${DIR}/mangos"
DATABASE_DIR="${DIR}/db"

# find mangos hash
cd MANGOS_DIR
MANGOS_HASH=$(git ls-tree --abbrev=8 HEAD mangos/ | grep -oP "commit \K\w+")
echo "[Build] The current mangos Hash is: ${MANGOS_HASH}"
# find database hash
cd DATABASE_DIR
DATABASE_HASH=$(git ls-tree --abbrev=8 HEAD db/ | grep -oP "commit \K\w+")
echo "[Build] The current db Hash is: ${DATABASE_HASH}"

# find build & run dir
BUILD_DIR="${DIR}/build/mangos-${MANGOS_HASH}_db-${DATABASE_HASH}"
RUN_DIR="${DIR}/run/mangos-${MANGOS_HASH}_db-${DATABASE_HASH}"
LOG_DIR="${DIR}/log/mangos-${MANGOS_HASH}_db-${DATABASE_HASH}"

# die on directory exists
#[ -d "${BUILD_DIR}" ] && echo "Error: Build Directory ${BUILD_DIR} already exists - stopping build." && exit 1
#[ -d "${RUN_DIR}" ] && echo "Error: Run Directory ${RUN_DIR} already exists - stopping build." && exit 1

# makedir in build, log & run
echo "[Build] Make Build, Log & Run Directory"
mkdir $BUILD_DIR
mkdir $RUN_DIR
mkdir $LOG_DIR

# cd BUILD_DIR
cd $BUILD_DIR

# build
echo "[Build] CMake clear"
(cmake clear | tee $LOG_DIR/cmake.log) 3>&1 1>&2 2>&3 | tee $LOG_DIR/cmake.error.log
echo "[Build] CMake in ${MANGOS_DIR}"
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
    | tee $LOG_DIR/cmake.log) 3>&1 1>&2 2>&3 | tee $LOG_DIR/cmake.error.log

echo "[Build] Make"
(make | tee $LOG_DIR/make.log) 3>&1 1>&2 2>&3 | tee $LOG_DIR/make.error.log
echo "[Build] Make install"
(make install | tee $LOG_DIR/make.log) 3>&1 1>&2 2>&3 | tee $LOG_DIR/make.error.log

# create symlinks for configs
echo "[Build] Link config files"
CONFIG_DIR="${DIR}/config/"
ln -s -f $CONFIG_DIR/ahbot.conf $RUN_DIR/etc/ahbot.conf
ln -s -f $CONFIG_DIR/mangosd.conf $RUN_DIR/etc/mangosd.conf
ln -s -f $CONFIG_DIR/playerbot.conf $RUN_DIR/etc/playerbot.conf
ln -s -f $CONFIG_DIR/realmd.conf $RUN_DIR/etc/realmd.conf

# save executable links & build hashes
echo "[Build] Save executable links & build hashes"
REALMD_LINK="$LOG_DIR/realmd-latest"
MANGOSD_LINK="$LOG_DIR/mangosd-latest"
echo "mangos-${MANGOS_HASH}_db-${DATABASE_HASH}" >> "$LOG_DIR/build-latest"
echo "${RUN_DIR}/bin/realmd" >> $REALMD_LINK
echo "${RUN_DIR}/bin/mangosd" >> $MANGOSD_LINK

# create symlinks for extractors
echo "[Build] Link map extractors"
WOW_DIR="${DIR}/data"
ln -s -f "${RUN_DIR}/bin/tools/ad" "${WOW_DIR}/ad" | chmod +x "${WOW_DIR}/ad"
ln -s -f "${RUN_DIR}/bin/tools/ExtractResources.sh" "${WOW_DIR}/ExtractResources.sh" | chmod +x "${WOW_DIR}/ExtractResources.sh"
ln -s -f "${RUN_DIR}/bin/tools/MoveMapGen" "${WOW_DIR}/MoveMapGen" | chmod +x "${WOW_DIR}/MoveMapGen"
ln -s -f "${RUN_DIR}/bin/tools/MoveMapGen.sh" "${WOW_DIR}/MoveMapGen.sh" | chmod +x "${WOW_DIR}/MoveMapGen.sh"
ln -s -f "${RUN_DIR}/bin/tools/offmesh.txt" "${WOW_DIR}/offmesh.txt"
ln -s -f "${RUN_DIR}/bin/tools/vmap_assembler" "${WOW_DIR}/vmap_assembler" | chmod +x "${WOW_DIR}/vmap_assembler"
ln -s -f "${RUN_DIR}/bin/tools/vmap_extractor" "${WOW_DIR}/vmap_extractor" | chmod +x "${WOW_DIR}/vmap_extractor"

echo "[Build] Finished"