#!/usr/bin/env bash

echo 'Testing tags'
echo 'Tags should be all, bar, baz'

../../bin/dotf init --prefix ./temp_dotf
../../bin/dotf tags bar baz --prefix ./temp_dotf
diff -rq ./temp_dotf ./dotf

rm -r ./temp_dotf
