#!/bin/bash

# directories
DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
BACKUP_DIR="${DIR}/backup/$(date +%F-%H:%M)/"
MANGOS_DIR="${DIR}/mangos"
CONFIG_DIR="${DIR}/config"

# Database
DB_REALM="vmangos_realmd"
DB_CHARACTERS="vmangos_characters"
DB_MANGOS="vmangos_mangos"
DB_LOGS="vmangos_logs"

cd ${DIR}

# stop server
echo "[Server] Stop Server"
${DIR}/stop.sh

# backup
echo "[Backup] Start Backup"
mkdir ${BACKUP_DIR}
ln -s -f ${BACKUP_DIR} ${DIR}/backup/latest

# backup realmd
echo "[Backup] Realmd Database"
mysqldump --defaults-extra-file=${DIR}/db.config ${DB_REALM} > ${BACKUP_DIR}/${DB_REALM}.sql

# backup characters
echo "[Backup] Characters Database"
mysqldump --defaults-extra-file=${DIR}/db.config ${DB_CHARACTERS} > $BACKUP_DIR/${DB_CHARACTERS}.sql

# backup logs
echo "[Backup] Logs Database"
mysqldump --defaults-extra-file=${DIR}/db.config ${DB_LOGS} > $BACKUP_DIR/${DB_LOGS}.sql

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
#echo "[Build] CMake clear"
(cmake ${MANGOS_DIR} clear | tee ${LOG_DIR}/cmake.log) 3>&1 1>&2 2>&3 | tee ${LOG_DIR}/cmake.error.log
echo "[Build] CMake in ${MANGOS_DIR}"
(cmake ${MANGOS_DIR} \
    -DCMAKE_INSTALL_PREFIX=${RUN_DIR} \
    -DPCH=1 \
    -DDEBUG=0 \
    -DSUPPORTED_CLIENT_BUILD=CLIENT_BUILD_1_12_1 \
    -DUSE_STD_MALLOC=0 \
    -DTBB_DEBUG=0 \
    -DUSE_ANTICHEAT=1 \
    -DSCRIPTS=1 \
    -DUSE_EXTRACTORS=1 \
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
echo "[Build] Link map extractors"
DATA_DIR="${DIR}/data"
ln -s -f "${RUN_DIR}/bin/mapextractor" "${DATA_DIR}/mapextractor" | chmod +x "${DATA_DIR}/mapextractor"
ln -s -f "${RUN_DIR}/bin/MoveMapGen" "${DATA_DIR}/MoveMapGen" | chmod +x "${DATA_DIR}/MoveMapGen"
ln -s -f "${RUN_DIR}/bin/vmap_assembler" "${DATA_DIR}/vmap_assembler" | chmod +x "${DATA_DIR}/vmap_assembler"
ln -s -f "${RUN_DIR}/bin/vmapextractor" "${DATA_DIR}/vmapextractor" | chmod +x "${DATA_DIR}/vmapextractor"

# install World Database Updates
echo "[Build] Update World Database"
for UPDATE in ${MANGOS_DIR}/sql/migrations/*_world.sql
do
    echo "    process update $UPDATE"
    mysql --defaults-extra-file="${DIR}/db.config" --database="${DB_MANGOS}" < $UPDATE 2> /dev/null
    [[ $? != 0 ]] && echo "    [skip] Could not apply $UPDATE"
done
echo
echo

# install Realm Database Updates
echo "[Build] Update Realm Database"
for UPDATE in ${MANGOS_DIR}/sql/migrations/*_logon.sql
do
    echo "    process update $UPDATE"
    mysql --defaults-extra-file="${DIR}/db.config" --database="${DB_REALM}" < $UPDATE 2> /dev/null
    [[ $? != 0 ]] && echo "    [skip] Could not apply $UPDATE"
done
echo
echo

# install Character Updates
echo "[Build] Update Character Database"
for UPDATE in ${MANGOS_DIR}/sql/migrations/*_characters.sql
do
    echo "    process update $UPDATE"
    mysql --defaults-extra-file="${DIR}/db.config" --database="${DB_CHARACTERS}" < $UPDATE 2> /dev/null
    [[ $? != 0 ]] && echo "    [skip] Could not apply $UPDATE"
done

# install Logs Updates
echo "[Build] Update Logs Database"
for UPDATE in ${MANGOS_DIR}/sql/migrations/*_logs.sql
do
    echo "    process update $UPDATE"
    mysql --defaults-extra-file="${DIR}/db.config" --database="${DB_LOGS}" < $UPDATE 2> /dev/null
    [[ $? != 0 ]] && echo "    [skip] Could not apply $UPDATE"
done

# Finish
echo "[Build] Finished"

# start server
echo "[Server] Start Server"
$DIR/start.sh
