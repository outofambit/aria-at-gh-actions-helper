#!/bin/bash

set -euo pipefail

os="$(uname)"
arch="$(uname -m)"
apiToken="$token"
apiURL="https://api.github.com/repos/mozilla/geckodriver/releases/latest"

if [[ "$os" == "Darwin" ]]; then

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


  case "$arch" in
    "arm64")
      echo "Downloading geckodriver"
      wget https://github.com/mozilla/geckodriver/releases/download/${latestVersion}/geckodriver-${latestVersion}-macos-aarch64.tar.gz

      tar xzf geckodriver-${latestVersion}-macos-aarch64.tar.gz
      ;;
    "x86_64")
    echo "Downloading geckodriver"
      wget https://github.com/mozilla/geckodriver/releases/download/${latestVersion}/geckodriver-${latestVersion}-macos.tar.gz
      tar xzf geckodriver-${latestVersion}-macos.tar.gz
      ;;
    *)
      echo "Unsupported architecture - $arch"
      exit 1
      ;;
  esac

  chmod +x geckodriver
  echo "Adding geckodriver to PATH"
  export PATH="$(pwd):${PATH}"
  cd ..
  echo "Running geckodriver --version"
  geckodriver --version
  echo "Running which geckodriver"
  which geckodriver
  exit 0
else
  echo "Unsupported OS - ${os}"
  exit 1
fi



