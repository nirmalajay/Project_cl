#!/bin/bash

# Replace these variables with your actual values
GITHUB_TOKEN="your_github_token"
ORG_NAME="your_org_name"
TEAMS_WEBHOOK_URL="https://bosch.webhook.office.com/webhookb2/d75b0c0e-024d-4ccd-a5a5-e7047f3e3717@0ae51e19-07c8-4e4b-bb6d-648ee58410f4/IncomingWebhook/4037f27c3524412eabf8b6819116b348/7322bd98-03dc-458e-b173-161109337c34l"

# GitHub API endpoint for organization self-hosted runners
API_URL="https://api.github.com/orgs/$ORG_NAME/actions/runners"

# Function to send alert to Microsoft Teams
send_alert() {
  local runner_name=$1
  local runner_status=$2
  curl -H 'Content-Type: application/json' -d "{\"text\": \"Alert: The GitHub self-hosted runner '$runner_name' is $runner_status.\"}" $TEAMS_WEBHOOK_URL
}

# Fetch the runners' status from GitHub API
response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" $API_URL)

# Debugging: Output the response to verify it's correct
echo "API Response: $response"

# Check if response is empty or contains errors
if [[ -z "$response" ]]; then
  echo "Error: Empty response from GitHub API"
  exit 1
fi

# Validate the response is a valid JSON
if ! echo "$response" | jq empty; then
  echo "Error: Invalid JSON response"
  exit 1
fi

# Extract runners' details
runners=$(echo "$response" | jq -c '.runners[]')

# Debugging: Output the extracted runners details
echo "Extracted Runners: $runners"

# Check each runner's status
echo "$runners" | while read -r runner; do
  # Debugging: Output the raw runner JSON
  echo "Raw Runner JSON: $runner"

  name=$(echo "$runner" | jq -r '.name')
  status=$(echo "$runner" | jq -r '.status')

  # Debugging: Output the extracted name and status
  echo "Extracted Runner Name: $name"
  echo "Extracted Runner Status: $status"

  if [ "$status" != "online" ]; then
    echo "Sending alert for Runner: $name, Status: $status"  # Debugging line
    send_alert "$name" "$status"
  fi
done
