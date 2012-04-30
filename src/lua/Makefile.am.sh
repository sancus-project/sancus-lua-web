#!/bin/sh

find_lua() {
	find "$@" -name '*.lua' | sort -V | tr '\n' ' ' | fmt -w60 | tr '\n' '|' |
		sed -e 's,|$,,' -e 's,|, \\\n\t,g'
}

cd "${0%/*}"
cat <<EOT | tee Makefile.am
nobase_dist_luadata_DATA = \\
	$(find_lua sancus)

luadatadir = @datadir@/lua/5.1
EOT
