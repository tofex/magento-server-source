#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -g  Add git branch
  -i  Include Magento files
  -u  Upload file to Tofex server

Example: ${scriptName} -u
EOF
}

trim()
{
  echo -n "$1" | xargs
}

#git=0
includeMagentoFiles=0
upload=0

while getopts hgiu? option; do
  case "${option}" in
    h) usage; exit 1;;
    #g) git=1;;
    i) includeMagentoFiles=1;;
    u) upload=1;;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

if [[ "${magentoVersion:0:1}" == 1 ]]; then
  magentoExcludeList="${currentPath}/lists/exclude-1.list"
else
  magentoExcludeList="${currentPath}/lists/exclude-2.list"
fi

if [[ ! -f "${magentoExcludeList}" ]]; then
  echo "No exclude list found. Expected at: ${magentoExcludeList}"
  exit 1
fi

sourceExcludeFile="${currentPath}/exclude.list"

if [[ ! -f "${sourceExcludeFile}" ]]; then
  echo "No exclude list generated"
  exit 1
fi

dumpExcludeList="/tmp/dump-exclude.list"

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

while IFS='' read -r line || [[ -n "$line" ]]; do
  echo "${line}" >> "${dumpExcludeList}"
done < "${sourceExcludeFile}"

date=$(date +%Y-%m-%d)

cd "${currentPath}"
rm -rf /tmp/repo

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
      echo "--- Dumping on local server: ${server} ---"

      #if [[ ${git} -eq 1 ]]; then
      #    git clone ${repoUrl} /tmp/repo
      #    cd /tmp/repo
      #    masterExists=$(git rev-parse --verify master 2>/dev/null | wc -l)
      #    if [[ ${masterExists} -eq 1 ]]; then
      #        git checkout -b production-${date} master
      #    fi
      #    cd ..
      #fi

      rsyncExcludeList=/tmp/dump-rsync-exclude.list
      cat "${dumpExcludeList}" | cut -c 2- > "${rsyncExcludeList}"
      echo "/vcs-info.txt" >> "${rsyncExcludeList}"
      echo "Syncing files from path: ${webPath} to path: /tmp/repo/"
      rsync --recursive --checksum --executability --no-owner --no-group --delete --force --verbose "--exclude-from=${rsyncExcludeList}" --quiet "${webPath}/" /tmp/repo/
      echo "Cleaning up code"
      find /tmp/repo/ -type d -empty -not -path "*/.git/*" -delete

      cd /tmp/repo
      #if [[ ${git} -eq 1 ]]; then
      #    git config user.name "Tofex Install"
      #    git config user.email "install@tofex.de"
      #    git add --all
      #    git commit -m "Added production files on ${date}"
      #    if [[ ${masterExists} -eq 1 ]]; then
      #        git push -u origin production-${date} | cat
      #    else
      #        git push -u origin master | cat
      #    fi
      #else
        dumpPath="${currentPath}/dumps"
        mkdir -p "${dumpPath}"
        echo "Creating dump file at: ${dumpPath}/source-${date}.tar.gz"
        tar -zcf "${dumpPath}/source-${date}.tar.gz" .
        if [[ "${upload}" -eq 1 ]]; then
          "${currentPath}/upload-dump.sh" -d "${date}"
        fi
      #fi
      cd "${currentPath}"

      echo "Removing synced files"
      rm -rf /tmp/repo
    fi
  fi
done
