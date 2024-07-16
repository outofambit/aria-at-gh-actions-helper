#!/bin/bash

set -euo pipefail

# When run in macOS, the test harness does not use WebDriver because
# SafariDriver's "glass pane" feature interferes with testing. Provide a valid
# URL simply as a placeholder.
url_placeholder=http://127.0.0.1:4444

aria-at-automation-driver/package/bin/at-driver serve --port 3031 > at-driver.log 2>&1 &

atdriver_pid=$!

poll_url(url) {
  local max_attempts=30
  local attempt=0

  while [ $attempt -lt $max_attempts ]; do
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    if [ "$response" -ge 99 ]; then
      Write-Output "${status} after ${attempts} tries"
      return true
    else
      echo "Attempt $((attempt+1))/$max_attempts: URL $url returned HTTP $response. Retrying in $timeout seconds..."
      sleep 1
      ((attempt++))
    fi
  done

  echo "Error: Max attempts reached. URL $url is not responding with a success code."
  kill -9 ${atdriver_pid} || true
  exit 1
}

case ${BROWSER} in
  chrome)
    echo "Starting chromedriver"
    chromedriver --port=4444 --log-level=INFO > webdriver.log 2>&1 &
    echo "Started chromedriver"
    poll_url($url_placeholder)
    ;;

  firefox)
    echo "Starting geckodriver"
    geckodriver > webdriver.log 2>&1 &
    echo "Started geckodriver"
    poll_url($url_placeholder)
    ;;

  safari)
    ;;

  *)
    echo "Unknown browser (${BROWSER})"
    kill -9 ${atdriver_pid} || true
    exit 1
    ;;
esac

webdriver_pid=$!

function clean_up {
  kill -9 ${webdriver_pid} || true
  kill -9 ${atdriver_pid} || true
}
trap clean_up EXIT

node aria-at-automation-harness/bin/host.js run-plan \
  --plan-workingdir aria-at/build/${ARIA_AT_WORK_DIR} \
  --debug \
  --agent-web-driver-url=${url_placeholder} \
  --agent-at-driver-url=ws://127.0.0.1:3031/session \
  --reference-hostname=127.0.0.1 \
  --agent-web-driver-browser=${BROWSER} \
  '{reference/**,test-*-voiceover_macos.*}' 2>&1 | \
    tee harness-run.log
