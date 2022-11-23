#!/bin/sh -l

cat /github/workspace/
cd /github/workspace/
godoc -v -http=:6060 & disown

echo "GODOCS FOR $1"
