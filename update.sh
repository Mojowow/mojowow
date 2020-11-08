#!/bin/bash

DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

cd $DIR
# git pull --ff-only

git submodule update --remote --checkout

# DB_DIR="${DIR}/db-tbc"
# MANGOS_DIR="${DIR}/mangos-tbc"

# Update Mangos
# cd $MANGOS_DIR
# git pull --ff-only

# Update DB
# cd $DB_DIR
# git pull --ff-only

