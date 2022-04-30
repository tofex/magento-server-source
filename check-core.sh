#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

while getopts h? option; do
  case "${option}" in
    h) usage; exit 1;;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")
if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version!"
  exit 1
fi

rm -rf /tmp/magento
mkdir -p /tmp/magento
cd /tmp/magento

if [[ "${magentoVersion:0:2}" == 19 ]]; then
  touch composer.json
  echo "{\"extra\": {\"magento-core-package-type\": \"magento-source\", \"magento-root-dir\": \".\"}}" > composer.json
  composer require aydin-hassan/magento-core-composer-installer
  composer require "openmage/magento-lts:${magentoVersion}"
fi

cd "${currentPath}"

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webServer")
  if [[ -n "${webServer}" ]]; then
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${type}" == "local" ]]; then
      webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
      echo "--- Checking on local server: ${server} ---"

      filesListFile="${currentPath}/lists/files-${magentoVersion}.list"

      if [[ ! -f "${filesListFile}" ]]; then
        echo "Missing files file list: ${filesListFile}"
        exit 1
      fi

      coreFiles=( $(cat "${filesListFile}") )

      for coreFile in "${coreFiles[@]}"; do
        localFile="${webPath}/${coreFile}"

        if [[ ! -f "${localFile}" ]]; then
          echo "Missing file: ${coreFile}"
        fi
      done

      for coreFile in "${coreFiles[@]}"; do
        if [[ "${coreFile}" == ".htaccess" ]] || [[ "${coreFile}" == "app/etc/modules/Cm_RedisSession.xml" ]]; then
          continue
        fi

        localFile="${webPath}/${coreFile}"

        if [[ -f "${localFile}" ]]; then
          sourceFile="/tmp/magento/${coreFile}"

          if [[ "${coreFile}" == "lib/Zend/Service/WindowsAzure/CommandLine/Scaffolders/DefaultScaffolder/resources/ServiceDefinition.csdef" ]]; then
            sed -i '1s/^\xEF\xBB\xBF//' "${sourceFile}"
          fi

          diff=$(diff -b -Z -b -B "${sourceFile}" "${localFile}" | cat)

          if [[ -n "${diff}" ]]; then
            echo ""
            echo "------ File is different: ${coreFile} ------"
            echo "${diff}"
          fi
        fi
      done
    fi
  fi
done
