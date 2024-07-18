#!/bin/bash

set -euo pipefail

sysArch="$(uname -om)"
apiToken="$token"
apiURL="https://api.github.com/repos/mozilla/geckodriver/releases/latest"

if [[ "$sysArch" == "Darwin arm64" ]]; then

  # Add Authorization header if a token is provided
  if [ -n "$token" ]; then
    authHeader="Authorization: token $apiToken"
  else
    authHeader=""
  fi
  # Make the API request and extract the tag_name
  latestVersion=$(curl -s -H "$authHeader" "$apiURL" | awk -F'"' '/tag_name/{print $4}')

  if [ -z "$latestVersion" ]; then
    echo "Failed to get latest version"
    exit 1
  fi

  echo "Found latest version of geckodriver ${latestVersion}"

  mkdir -p geckodriver
  cd geckodriver
  wget https://github.com/mozilla/geckodriver/releases/download/${latestVersion}/geckodriver-${latestVersion}-macos.tar.gz
  tar xzf geckodriver-${latestVersion}-macos.tar.gz
  chmod +x geckodriver
  PATH="$(pwd):${PATH}"
  geckodriver --version
  exit 0
else
  echo "Unsupported OS + architecture - ${sysArch}"
  exit 1
fi



