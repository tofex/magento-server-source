#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -n  Name of repository
  -u  Url of repository
  -t  Type of repository, default: composer
  -c  Composer user of repository
  -p  Password of composer user

Example: ${scriptName} -n tofex -u https://composer.tofex.de -c 12345 -p 67890
EOF
}

trim()
{
  echo -n "$1" | xargs
}

repositoryName=
repositoryUrl=
repositoryType=
repositoryComposerUser=
repositoryComposerPassword=

while getopts hn:u:t:c:p:? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) repositoryName=$(trim "$OPTARG");;
    u) repositoryUrl=$(trim "$OPTARG");;
    t) repositoryType=$(trim "$OPTARG");;
    c) repositoryComposerUser=$(trim "$OPTARG");;
    p) repositoryComposerPassword=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${repositoryName}" ]]; then
  echo "No repository name specified!"
  usage
  exit 1
fi

if [[ -z "${repositoryUrl}" ]]; then
  echo "No repository url specified!"
  usage
  exit 1
fi

if [[ -z "${repositoryType}" ]]; then
  repositoryType="composer"
fi

if [[ -z "${repositoryComposerUser}" ]]; then
  echo "No composer user specified!"
  usage
  exit 1
fi

if [[ -z "${repositoryComposerPassword}" ]]; then
  echo "No composer password specified!"
  usage
  exit 1
fi

"${currentPath}/../core/script/run.sh" "webServer" "${currentPath}/add-repository/web-server.sh" \
  --repositoryName "${repositoryName}" \
  --repositoryUrl "${repositoryUrl}" \
  --repositoryType "${repositoryType}" \
  --repositoryComposerUser "${repositoryComposerUser}" \
  --repositoryComposerPassword "${repositoryComposerPassword}"
