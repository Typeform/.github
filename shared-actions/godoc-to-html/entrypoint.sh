#!/bin/sh

PATH_GOMOD="$(dirname "$(find . -name 'go.mod' | head -n 1)")" || exit 1
cd $PATH_GOMOD

mkdir -p "$GOPATH/src/github.com/$GITHUB_REPOSITORY"
cp -r * "$GOPATH/src/github.com/$GITHUB_REPOSITORY"

go mod vendor
godoc -v -http=:6060 &

REPO=$GITHUB_REPOSITORY
if [ $PATH_GOMOD != "." ]
then
  REPO="${GITHUB_REPOSITORY}${PATH_GOMOD:1}"
fi

wget --reject-regex "(.*)\?(.*)" -m -r -N -E -p -k -nd -q --include-directories="/lib,/pkg/github.com/$REPO,/src/github.com/$REPO" --exclude-directories="*" --no-host-directories --directory-prefix=godocs http://localhost:6060/pkg/github.com/$REPO

chmod -R 777 godocs
mv godocs /github/workspace/

exit 0
