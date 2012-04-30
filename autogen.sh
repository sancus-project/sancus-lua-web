#!/bin/sh

case "$0" in
*/*) BASE="${0%/*}" ;;
*) BASE=. ;;
esac

mkdir -p "$BASE/m4"
exec autoreconf -ivs "${BASE}"
