#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help                 Show this message
  --includeMagentoFiles  Include Magento files
  --upload               Upload file to Tofex server

Example: ${scriptName} --upload
EOF
}

includeMagentoFiles=0
upload=0

source "${currentPath}/../core/prepare-parameters.sh"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

magentoVersion=$(ini-parse "${currentPath}/../env.properties" "yes" "install" "magentoVersion")

versionExcludeList="${currentPath}/lists/files-${magentoVersion}.list"

if [[ "${includeMagentoFiles}" == 0 ]] && [[ ! -f "${versionExcludeList}" ]]; then
  echo "No file list found. Expected at: ${versionExcludeList}"
  exit 1
fi

magentoExcludeList="${currentPath}/lists/exclude-${magentoVersion:0:1}.list"

if [[ ! -f "${magentoExcludeList}" ]]; then
  echo "No exclude list found. Expected at: ${magentoExcludeList}"
  exit 1
fi

sourceExcludeFile="${currentPath}/../var/source/exclude.list"

sourcePath="${currentPath}/../var/source"
sourceTempPath="${sourcePath}/tmp"

mkdir -p "${sourceTempPath}"

dumpExcludeList="${sourceTempPath}/dump-exclude.list"

rm -rf "${dumpExcludeList}"
touch "${dumpExcludeList}"

if [[ "${includeMagentoFiles}" == 0 ]]; then
  while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "./${line}" >> "${dumpExcludeList}"
  done < "${versionExcludeList}"
fi

while IFS='' read -r line || [[ -n "$line" ]]; do
  echo "${line}" >> "${dumpExcludeList}"
done < "${magentoExcludeList}"

if [[ -f "${sourceExcludeFile}" ]]; then
  while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "${line}" >> "${dumpExcludeList}"
  done < "${sourceExcludeFile}"
else
  echo "No source exclude list available."
fi

magentoIncludeList="${currentPath}/lists/include-${magentoVersion:0:1}.list"

if [[ ! -f "${magentoIncludeList}" ]]; then
  echo "No include list found. Expected at: ${magentoIncludeList}"
  exit 1
fi

sourceIncludeFile="${currentPath}/../var/source/include.list"

dumpIncludeList="${sourceTempPath}/dump-include.list"

rm -rf "${dumpIncludeList}"
touch "${dumpIncludeList}"

while IFS='' read -r line || [[ -n "$line" ]]; do
  echo "${line}" >> "${dumpIncludeList}"
done < "${magentoIncludeList}"

if [[ -f "${sourceIncludeFile}" ]]; then
  while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "${line}" >> "${dumpIncludeList}"
  done < "${sourceIncludeFile}"
else
  echo "No source include list available."
fi

date=$(date +%Y-%m-%d)

dumpRepoPath="${sourceTempPath}/repo"

cd "${currentPath}"
rm -rf "${dumpRepoPath}"

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")

  if [[ -n "${webServer}" ]]; then
    type=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")

    if [[ "${type}" == "local" ]]; then
      echo "--- Dumping on local server: ${server} ---"
      webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${webServer}" "path")

      rsyncExcludeList="${sourceTempPath}/dump-rsync-exclude.list"
      cat "${dumpExcludeList}" | cut -c 2- > "${rsyncExcludeList}"
      echo "/.git" >> "${rsyncExcludeList}"
      echo "/.gitignore" >> "${rsyncExcludeList}"
      echo "/vcs-info.txt" >> "${rsyncExcludeList}"

      rsyncIncludeList="${sourceTempPath}/dump-rsync-include.list"
      cat "${dumpIncludeList}" | cut -c 2- > "${rsyncIncludeList}"

      echo "Syncing files from path: ${webPath} to path: ${dumpRepoPath}"
      rsync --recursive --checksum --executability --no-owner --no-group --delete --force --verbose "--exclude-from=${rsyncExcludeList}" --quiet "${webPath}/" "${dumpRepoPath}/"
      rsync --recursive --checksum --executability --no-owner --no-group --force --verbose "--files-from=${rsyncIncludeList}" --quiet "${webPath}/" "${dumpRepoPath}/"

      echo "Cleaning up code"
      find "${dumpRepoPath}/" -type d -empty -delete

      dumpPath="${sourcePath}/dumps"
      mkdir -p "${dumpPath}"
      echo "Creating dump file at: ${dumpPath}/source-${date}.tar.gz"
      cd "${dumpRepoPath}"
      tar -zcf "${dumpPath}/source-${date}.tar.gz" .
      cd "${currentPath}"

      if [[ "${upload}" -eq 1 ]]; then
        "${currentPath}/upload-dump.sh" -d "${date}"
      fi

      echo "Removing synced files"
      rm -rf "${dumpRepoPath}"
    fi
  fi
done
