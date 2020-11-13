#!/bin/bash
DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $DIR

run/realmd.sh stop
run/mangosd.sh stop