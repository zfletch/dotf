#!/usr/bin/env bash

echo 'Testing key'
echo 'Key should be zoboomafoo'

../../bin/dotf init --prefix ./temp_dotf
../../bin/dotf key zoboomafoo --prefix ./temp_dotf
diff -rq ./temp_dotf ./dotf

rm -r ./temp_dotf
