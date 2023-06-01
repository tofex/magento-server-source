#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help      Show this message
  --webPath   Web path
  --webUser   Web user (optional)
  --webGroup  Web group (optional)
  --active    Show only active modules

Example: ${scriptName}
EOF
}

webPath=
webUser=
webGroup=
active=

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

cd "${webPath}"

if [[ "${active}" == 1 ]]; then
  # shellcheck disable=SC2016
  php -r '$config = file_exists("app/etc/config.php") ? include "app/etc/config.php" : []; if (array_key_exists("modules", $config)) foreach ($config["modules"] as $moduleName => $active) if ($active) echo "$moduleName\n";'
else
  # shellcheck disable=SC2016
  php -r '$config = file_exists("app/etc/config.php") ? include "app/etc/config.php" : []; if (array_key_exists("modules", $config)) foreach (array_keys($config["modules"]) as $moduleName) echo "$moduleName\n";'
fi
