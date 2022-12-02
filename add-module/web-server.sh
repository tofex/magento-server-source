#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help            Show this message
  --magentoVersion  Magento version
  --webPath         Web path
  --webUser         Web user (optional)
  --webGroup        Web group (optional)
  --moduleName      Name of module
  --moduleVersion   Version of module

Example: ${scriptName}
EOF
}

magentoVersion=
webPath=
webUser=
webGroup=
moduleName=
moduleVersion=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  usage
  exit 1
fi

if [[ -z "${webPath}" ]]; then
  echo "No web path specified!"
  usage
  exit 1
fi

currentUser="$(whoami)"
if [[ -z "${webUser}" ]]; then
  webUser="${currentUser}"
fi

currentGroup="$(id -g -n)"
if [[ -z "${webGroup}" ]]; then
  webGroup="${currentGroup}"
fi

if [[ -z "${moduleName}" ]]; then
  echo "No module name specified!"
  usage
  exit 1
fi

if [[ -z "${moduleVersion}" ]]; then
  moduleVersion="any"
fi

cd "${webPath}"

if [[ "${moduleVersion}" == "any" ]]; then
  composer require "${moduleName}"
else
  composer require "${moduleName}:moduleVersion"
fi
