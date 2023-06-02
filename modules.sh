#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help    Show this message
  --active  Show only active modules

Example: ${scriptName}
EOF
}

active=

source "${currentPath}/../core/prepare-parameters.sh"

if [[ "${active}" == 1 ]]; then
  "${currentPath}/../core/script/run-quiet.sh" "webServer" "${currentPath}/modules/web-server.sh" --active | sort -n
else
  "${currentPath}/../core/script/run-quiet.sh" "webServer" "${currentPath}/modules/web-server.sh" | sort -n
fi
