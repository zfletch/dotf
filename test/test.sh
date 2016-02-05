#!/usr/bin/env bash

cd init
./test.sh
echo

cd ..
cd key
./test.sh
echo

cd ..
cd tags
./test.sh
echo

cd ..
cd run
./test.sh
echo
