#!/usr/bin/env bash

echo 'Testing init'

../../bin/dotf init --prefix ./temp_dotf
diff -rq ./temp_dotf ./dotf

rm -r ./temp_dotf
