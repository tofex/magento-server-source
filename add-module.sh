#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -m  Module to add
  -v  Version of the module (optional)

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

moduleName=
moduleVersion=

while getopts hm:v:? option; do
  case "${option}" in
    h) usage; exit 1;;
    m) moduleName=$(trim "$OPTARG");;
    v) moduleVersion=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${moduleName}" ]]; then
  echo "No module name specified!"
  usage
  exit 1
fi

if [[ -z "${moduleVersion}" ]]; then
  moduleVersion="any"
fi

"${currentPath}/../core/script/run.sh" "webServer" "${currentPath}/add-module/web-server.sh" \
  --moduleName "${moduleName}" \
  --moduleVersion "${moduleVersion}"
