#!/bin/sh -l

cat /github/workspace/
cd /github/workspace/
godoc -v -http=:6060 > /dev/null 2>&1

echo "GODOCS FOR $1"
