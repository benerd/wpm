#!/bin/bash

# GitHub App Credentials
APP_ID="1179405"
INSTALLATION_ID="62690225"
PRIVATE_KEY="${{ secrets.GH_APP_PRIVATE_KEY }}"

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

  HEADER_B64=$(echo -n "$HEADER" | openssl base64 -A | tr -d '=' | tr '/+' '_-')
  PAYLOAD_B64=$(echo -n "$PAYLOAD" | openssl base64 -A | tr -d '=' | tr '/+' '_-')

  SIGNATURE=$(echo -n "$HEADER_B64.$PAYLOAD_B64" | openssl dgst -sha256 -sign <(echo -n "$PRIVATE_KEY") | openssl base64 -A | tr -d '=' | tr '/+' '_-')

  echo "$HEADER_B64.$PAYLOAD_B64.$SIGNATURE"
}

# Generate JWT
JWT=$(generate_jwt)

# Fetch installation token from GitHub API
INSTALLATION_ACCESS_TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens" | jq -r '.token')

echo "$INSTALLATION_ACCESS_TOKEN"
