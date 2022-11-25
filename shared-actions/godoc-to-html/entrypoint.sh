#!/bin/sh

cd "$(dirname "$(find . -name 'go.mod' | head -n 1)")" || exit 1

mkdir -p "$GOPATH/src/github.com/$GITHUB_REPOSITORY"
cp -r * "$GOPATH/src/github.com/$GITHUB_REPOSITORY"

go mod vendor
godoc -v -http=:6060 &

wget -m -r -N -E -p -k -nd -q --include-directories="/lib,/pkg/github.com/$GITHUB_REPOSITORY,/src/github.com/$GITHUB_REPOSITORY" --exclude-directories="*" --no-host-directories --directory-prefix=godocs http://localhost:6060/pkg/github.com/$GITHUB_REPOSITORY
