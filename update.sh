#!/bin/bash

DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $DIR
DATE=date +"%m-%d-%y"

# update this repo
#TODO:git pull --ff-only

# find mangos hash
cd MANGOS_DIR
MANGOS_HASH=$(git ls-tree --abbrev=8 HEAD mangos/ | grep -oP "commit \K\w+")
echo "[Update] The current mangos Hash is: ${MANGOS_HASH}"
# find database hash
cd DATABASE_DIR
DATABASE_HASH=$(git ls-tree --abbrev=8 HEAD db/ | grep -oP "commit \K\w+")
echo "[UPDATE] The current db Hash is: ${DATABASE_HASH}"

# update all submodules
git submodule update --remote --checkout

# find new mangos hash
cd MANGOS_DIR
MANGOS_HASH_NEW=$(git ls-tree --abbrev=8 HEAD mangos/ | grep -oP "commit \K\w+")
echo "[Update] The new mangos Hash is: ${MANGOS_HASH_NEW}"
# find new database hash
cd DATABASE_DIR
DATABASE_HASH_NEW=$(git ls-tree --abbrev=8 HEAD db/ | grep -oP "commit \K\w+")
echo "[UPDATE] The new db Hash is: ${DATABASE_HASH_NEW}"

cd $DIR

# Git commit & push
git add mangos/
git add db/
git commit -m "Automatic Update: ${DATE} - Mangos: ${MANGOS_HASH_NEW} DB: ${DATABASE_HASH_NEW}"
#TODO:git push