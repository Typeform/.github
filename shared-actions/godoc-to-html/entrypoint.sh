#!/bin/sh -l

ls -la /github/workspace/
cd /github/workspace/
godoc -v -http=:6060 &

echo "GODOCS FOR $1"
