#!/bin/bash

set -euo pipefail

# When run in macOS, the test harness does not use WebDriver because
# SafariDriver's "glass pane" feature interferes with testing. Provide a valid
# URL simply as a placeholder.
url_placeholder=http://127.0.0.1:4444

aria-at-automation-driver/package/bin/at-driver serve --port 3031 > at-driver.log 2>&1 &

atdriver_pid=$!

poll_url() {
  local url="$1"
  local attempt=0
  echo "Polling ${url}"

  while [ ${attempt} -lt 30 ]; do
    ((attempt++))

    response=$(curl -s -o /dev/null -v -w "%{http_code}" -m 2 "$url" || true)

    if [ ${response:--1} -ge 99 ]; then
      echo "Success: ${response} after ${attempt} tries"
      return 0
    else
      echo "Attempt ${attempt}: URL ${url} returned HTTP ${response}. Retrying in 1 second..."
      sleep 1
    fi
  done

  echo "Error: Max attempts reached. ${url} is not responding."
  kill -9 ${atdriver_pid} || true
  exit 1
}

case ${BROWSER} in
  chrome)
    echo "Starting chromedriver"
    chromedriver --port=4444 --log-level=INFO > webdriver.log 2>&1 &
    echo "Started chromedriver"
    poll_url http://localhost:4444
    ;;

  firefox)
    echo "Starting geckodriver"
    which geckodriver > which-webdriver.log 2>&1 &
    geckodriver > webdriver.log 2>&1 &
    echo "exit code: $?"
    echo "Started geckodriver"
    poll_url http://localhost:4444
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
