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
  moduleList=( $("${currentPath}/../core/script/run-quiet.sh" "webServer" "${currentPath}/modules/web-server.sh" --active | sort -n) )
else
  moduleList=( $("${currentPath}/../core/script/run-quiet.sh" "webServer" "${currentPath}/modules/web-server.sh" | sort -n) )
fi

"${currentPath}/../core/script/run-quiet.sh" "install" "${currentPath}/third-party-modules/install.sh" \
  --modules "$(IFS=,; echo "${moduleList[*]}")" \
  --magentoVersionModuleList "file:${currentPath}/lists/modules-[magentoVersion].list" \
  --moduleIgnoreList "file:${currentPath}/lists/modules-ignore.list"
