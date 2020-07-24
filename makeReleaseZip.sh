#!/bin/bash -e

# ln -sfn haxe4_libraries haxe_libraries

npm install
npx lix download

npx haxe build.hxml
npx haxe test.hxml
npx haxe testSelfCoverage.hxml

rm -f instrument.zip
zip -9 -r -q instrument.zip src haxelib.json README.md CHANGELOG.md LICENSE.md
