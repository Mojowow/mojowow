#!/bin/bash

# directories
DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
BACKUP_DIR="${DIR}/backup/$(date +%F-%H:%M)/"
MANGOS_DIR="${DIR}/mangos"
CONFIG_DIR="${DIR}/config"

cd ${DIR}

# stop server
echo "[Server] Stop Server"
${DIR}/stop.sh

# backup
echo "[Backup] Start Backup"
mkdir ${BACKUP_DIR}
ln -s -f ${BACKUP_DIR} ${DIR}/backup/latest

# backup realmd
#echo "[Backup] Realmd Database"
#mysqldump --defaults-extra-file=${DIR}/db.config tbcrealmd > $BACKUP_DIR/reamld.sql

# backup characters
#echo "[Backup] Characters Database"
#mysqldump --defaults-extra-file=${DIR}/db.config tbccharacters > $BACKUP_DIR/characters.sql

#update
echo "[Update] Start Update"
# update this repo
git pull --ff-only


# find mangos hash
MANGOS_HASH=$(git ls-tree --abbrev=8 HEAD mangos/ | grep -oP "commit \K\w+")
echo "[Update] The current mangos Hash is: ${MANGOS_HASH}"

# update all submodules
git submodule update --remote --checkout

# find new mangos hash
MANGOS_HASH_NEW=$(git ls-tree --abbrev=8 HEAD mangos/ | grep -oP "commit \K\w+")
echo "[Update] The new mangos Hash is: ${MANGOS_HASH_NEW}"

# Git commit & push
cd ${DIR}
DATE=$(date +"%m-%d-%y")
git add mangos/
git commit -m "Automatic Update: ${DATE} - Mangos: ${MANGOS_HASH_NEW}"
git push

# Update MANGOS_HASH var
MANGOS_HASH=${MANGOS_HASH_NEW}

# build
echo "[Build] Start building"

# find build, run & log dir
BUILD_DIR="${DIR}/build/mangos-${MANGOS_HASH}"
RUN_DIR="${DIR}/run/mangos-${MANGOS_HASH}"
LOG_DIR="${DIR}/log/mangos-${MANGOS_HASH}"

# makedir in build, run & log
echo "[Build] Make build, run & log directory"
mkdir ${BUILD_DIR}
mkdir ${RUN_DIR}
mkdir ${LOG_DIR}

cd ${BUILD_DIR}

# build
echo "[Build] CMake clear"
(cmake clear | tee ${LOG_DIR}/cmake.log) 3>&1 1>&2 2>&3 | tee ${LOG_DIR}/cmake.error.log
echo "[Build] CMake in ${MANGOS_DIR}"
(cmake ${MANGOS_DIR} \
    -DCMAKE_INSTALL_PREFIX=${RUN_DIR} \
    -DPCH=1 \
    -DDEBUG=0 \
    -DUSE_LIBCURL=1 \
    | tee ${LOG_DIR}/cmake.log) 3>&1 1>&2 2>&3 | tee ${LOG_DIR}/cmake.error.log

echo "[Build] Make"
(make -j 4 | tee ${LOG_DIR}/make.log) 3>&1 1>&2 2>&3 | tee ${LOG_DIR}/make.error.log
echo "[Build] Make install"
(make install | tee ${LOG_DIR}/make.log) 3>&1 1>&2 2>&3 | tee ${LOG_DIR}/make.error.log

# create symlinks for configs
echo "[Build] Link config files"
ln -s -f ${CONFIG_DIR}/mangosd.conf ${RUN_DIR}/etc/mangosd.conf
ln -s -f ${CONFIG_DIR}/realmd.conf ${RUN_DIR}/etc/realmd.conf

# save executable links & build hashes
echo "[Build] Save executable links & build hashes"
REALMD_LINK="${DIR}/log/realmd-latest"
MANGOSD_LINK="${DIR}/log/mangosd-latest"
LOG_LINK="${DIR}/log/log-latest"
echo "mangos-${MANGOS_HASH}" >> "${DIR}/log/build-latest"
echo "${RUN_DIR}/bin/realmd" >> $REALMD_LINK
echo "${RUN_DIR}/bin/mangosd" >> $MANGOSD_LINK
echo ${LOG_DIR} > ${LOG_LINK}
ln -s -f ${RUN_DIR}/bin/realmd ${DIR}/run/realmd
ln -s -f ${RUN_DIR}/bin/mangosd ${DIR}/run/mangosd
ln -s -f ${LOG_DIR} ${DIR}/log/latest
ln -s -f ${BUILD_DIR} ${DIR}/build/latest

# create symlinks for extractors
#echo "[Build] Link map extractors"
#WOW_DIR="${DIR}/data"
#ln -s -f "${RUN_DIR}/bin/tools/ad" "${WOW_DIR}/ad" | chmod +x "${WOW_DIR}/ad"
#ln -s -f "${RUN_DIR}/bin/tools/ExtractResources.sh" "${WOW_DIR}/ExtractResources.sh" | chmod +x "${WOW_DIR}/ExtractResources.sh"
#ln -s -f "${RUN_DIR}/bin/tools/MoveMapGen" "${WOW_DIR}/MoveMapGen" | chmod +x "${WOW_DIR}/MoveMapGen"
#ln -s -f "${RUN_DIR}/bin/tools/MoveMapGen.sh" "${WOW_DIR}/MoveMapGen.sh" | chmod +x "${WOW_DIR}/MoveMapGen.sh"
#ln -s -f "${RUN_DIR}/bin/tools/offmesh.txt" "${WOW_DIR}/offmesh.txt"
#ln -s -f "${RUN_DIR}/bin/tools/vmap_assembler" "${WOW_DIR}/vmap_assembler" | chmod +x "${WOW_DIR}/vmap_assembler"
#ln -s -f "${RUN_DIR}/bin/tools/vmap_extractor" "${WOW_DIR}/vmap_extractor" | chmod +x "${WOW_DIR}/vmap_extractor"

# install world db
#echo "[Build] Install World Database"
#cd $DIR/db
#./InstallFullDB.sh

# install Realm Database Updates
#echo "[Build] Update Realm Database"
#for UPDATE in ${MANGOS_DIR}/sql/updates/realmd/*.sql
#do
#    echo "    process update $UPDATE"
#    mysql --defaults-extra-file="${DIR}/db.config" --database="tbcrealmd" < $UPDATE 2> /dev/null
#    [[ $? != 0 ]] && echo "    [skip] Could not apply $UPDATE"
#done
#echo
#echo

# install Character Updates
#echo "[Build] Update Character Database"
#for UPDATE in ${MANGOS_DIR}/sql/updates/characters/*.sql
#do
#    echo "    process update $UPDATE"
#    mysql --defaults-extra-file="${DIR}/db.config" --database="tbccharacters" < $UPDATE 2> /dev/null
#    [[ $? != 0 ]] && echo "    [skip] Could not apply $UPDATE"
#done

# Finish
#echo "[Build] Finished"

# start server
#echo "[Server] Start Server"
#$DIR/start.sh
