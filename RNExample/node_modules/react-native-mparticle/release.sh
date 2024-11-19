#!/usr/bin/env bash
: ${1?"NPM Token missing- usage: $0 {MY_NPM_TOKEN}"}

touch .npmrc;
echo "//registry.npmjs.org/:_authToken=$1" > .npmrc;
npm publish;