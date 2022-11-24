#!/bin/sh -l

cd /github/workspace/go
ls -la .

mkdir -p "$GOPATH/src/github.com/$GITHUB_REPOSITORY"
cp -r * "$GOPATH/src/github.com/$GITHUB_REPOSITORY"

godoc -v -http=:6060 &

REPOSITORY_NAME=blocks/go

wget -m -r -N -E -p -k -nd -q --include-directories="/lib,/pkg/github.com/Typeform/blocks/go,/src/github.com/Typeform/blocks/go" --exclude-directories="*" --no-host-directories --directory-prefix=godocs http://localhost:6060/pkg/github.com/Typeform/blocks/go

mkdir -p /github/workspace/build-docs/blocks/godocs
mv godocs /github/workspace/build-docs/blocks
