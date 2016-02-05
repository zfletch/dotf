#!/usr/bin/env bash

echo 'Testing run'

../../bin/dotf run --prefix ./dotf

diff ./temp\ file ./result

rm -r ./temp\ file
