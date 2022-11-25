#!/bin/sh

REPOSITORY_NAME=blocks/go

cd /github/workspace/go

mkdir -p "$GOPATH/src/github.com/$GITHUB_REPOSITORY"
cp -r * "$GOPATH/src/github.com/$GITHUB_REPOSITORY"

go mod vendor
godoc -v -http=:6060 &

wget -m -r -N -E -p -k -nd -q --include-directories="/lib,/pkg/github.com/Typeform/$GITHUB_REPOSITORY,/src/github.com/Typeform/$GITHUB_REPOSITORY" --exclude-directories="*" --no-host-directories --directory-prefix=godocs http://localhost:6060/pkg/github.com/Typeform/$GITHUB_REPOSITORY
