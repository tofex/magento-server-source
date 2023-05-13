#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help                      Show this message
  --modules                   List of active modules
  --magentoVersionModuleList  List file of modules of Magento version
  --moduleIgnoreList          List of modules to ignore

Example: ${scriptName}
EOF
}

modules=
magentoVersionModuleList=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
fi

if [[ -z "${modules}" ]]; then
  echo "No active module list specified!"
  usage
  exit 1
fi

if [[ -z "${magentoVersionModuleList}" ]]; then
  echo "No Magento version module list specified!"
  usage
  exit 1
fi

if [[ -z "${moduleIgnoreList}" ]]; then
  echo "No module ignore list specified!"
  usage
  exit 1
fi

IFS=', ' read -r -a moduleList <<< "${modules}"

printf "%s\n" "${moduleList[@]}" > /tmp/module_list.txt

cat "${magentoVersionModuleList}" > /tmp/magento_list.txt
cat "${moduleIgnoreList}" >> /tmp/magento_list.txt

grep -Fxvf /tmp/magento_list.txt /tmp/module_list.txt

rm -rf /tmp/magento_list.txt
rm -rf /tmp/module_list.txt
