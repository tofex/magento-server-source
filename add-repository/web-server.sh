#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help                        Show this message
  --webPath                     Web path
  --webUser                     Web user (optional)
  --webGroup                    Web group (optional)
  --repositoryName              Name of repository
  --repositoryUrl               Url of repository
  --repositoryType              Type of repository, default: composer
  --repositoryComposerUser      Composer user of repository
  --repositoryComposerPassword  Password of composer user

Example: ${scriptName} --webPath /var/www/magento/htdocs --repositoryName tofex --repositoryUrl https://composer.tofex.de --repositoryComposerUser 12345 --repositoryComposerPassword 67890
EOF
}

webPath=
webUser=
webGroup=
repositoryName=
repositoryUrl=
repositoryType=
repositoryComposerUser=
repositoryComposerPassword=

if [[ -f "${currentPath}/../../core/prepare-parameters.sh" ]]; then
  source "${currentPath}/../../core/prepare-parameters.sh"
elif [[ -f /tmp/prepare-parameters.sh ]]; then
  source /tmp/prepare-parameters.sh
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

cd "${webPath}"

repositoryHostName=$(echo "${repositoryUrl}" | awk -F[/:] '{print $4}')

echo "Adding composer repository: ${repositoryUrl}"
composer config --ansi --no-interaction "repositories.${repositoryName}" "${repositoryType}" "${repositoryUrl}"

echo "Adding access to repository: ${repositoryUrl}"
composer config --ansi --no-interaction "http-basic.${repositoryHostName}" "${repositoryComposerUser}" "${repositoryComposerPassword}"
