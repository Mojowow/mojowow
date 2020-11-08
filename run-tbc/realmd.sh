#!/bin/bash

DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
EXECUTABLE=$( tail -n 1 ${DIR}/realmd-latest )

EXECUTABLE_DIR=$(dirname "${EXECUTABLE}")

cd $EXECUTABLE_DIR;
./realmd