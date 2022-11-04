#!/bin/sh -l

cat /github/workspace/
cd /github/workspace/
godoc -http=:6060

echo "GODOCS FOR $1"
