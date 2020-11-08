#!/bin/bash

DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $DIR

# update this repo
# git pull --ff-only

# update all submodules
git submodule update --remote --checkout

