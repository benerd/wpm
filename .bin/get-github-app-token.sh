#!/bin/bash

# Exit on error
set -e

# GitHub App Credentials
APP_ID="1179405"
INSTALLATION_ID="62690225"
PRIVATE_KEY_PATH="$1"

# Validate input
if [[ -z "$PRIVATE_KEY_PATH" || ! -f "$PRIVATE_KEY_PATH" ]]; then
  echo "Error: Private key file not found!"
  exit 1
fi

# Function to generate JWT
generate_jwt() {
  HEADER='{"alg":"RS256","typ":"JWT"}'
  NOW=$(date +%s)
  EXP=$(($NOW + 600))

  PAYLOAD=$(cat <<EOF
{
  "iat": $NOW,
  "exp": $EXP,
  "iss": $APP_ID
}
EOF
)

  HEADER_B64=$(echo -n "$HEADER" | base64 -w 0 | tr -d '=' | tr '/+' '_-')
  PAYLOAD_B64=$(echo -n "$PAYLOAD" | base64 -w 0 | tr -d '=' | tr '/+' '_-')

  # Corrected signature generation
  SIGNATURE=$(printf "%s" "$HEADER_B64.$PAYLOAD_B64" | openssl dgst -sha256 -sign "$PRIVATE_KEY_PATH" | base64 -w 0 | tr -d '=' | tr '/+' '_-')

  echo "$HEADER_B64.$PAYLOAD_B64.$SIGNATURE"
}

# Generate JWT
JWT=$(generate_jwt)

# Debug: Print JWT (remove after testing)
echo "Generated JWT: $JWT"

# Fetch installation token from GitHub API
INSTALLATION_ACCESS_TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens" | jq -r '.token')

# Debug: Check if token is retrieved
if [[ -z "$INSTALLATION_ACCESS_TOKEN" || "$INSTALLATION_ACCESS_TOKEN" == "null" ]]; then
  echo "Error: Failed to fetch GitHub App installation token."
  exit 1
fi

# Print token (useful for GitHub Actions)
echo "$INSTALLATION_ACCESS_TOKEN"
