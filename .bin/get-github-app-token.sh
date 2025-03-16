#!/bin/bash

# Exit on error
set -e

# GitHub App Credentials
APP_ID="1179405"
INSTALLATION_ID="62690225"
PRIVATE_KEY_PATH="$1"

# Validate input
if [[ -z "$PRIVATE_KEY_PATH" || ! -f "$PRIVATE_KEY_PATH" ]]; then
  >&2 echo "Error: Private key file not found or invalid!"
  >&2 echo "Usage: $0 <path-to-private-key.pem>"
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
  
  # More reliable base64 encoding for GitHub Actions
  HEADER_B64=$(echo -n "$HEADER" | openssl base64 -A | tr '+/' '-_' | tr -d '=')
  PAYLOAD_B64=$(echo -n "$PAYLOAD" | openssl base64 -A | tr '+/' '-_' | tr -d '=')
  
  # Improved signature generation
  SIGNATURE=$(echo -n "$HEADER_B64.$PAYLOAD_B64" | openssl dgst -sha256 -sign "$PRIVATE_KEY_PATH" -binary | openssl base64 -A | tr '+/' '-_' | tr -d '=')
  
  echo "$HEADER_B64.$PAYLOAD_B64.$SIGNATURE"
}

# Generate JWT
JWT=$(generate_jwt)

# Debug: Print first 20 chars of JWT (to stderr, not stdout)
>&2 echo "Generated JWT: ${JWT:0:20}..."

# Fetch installation token from GitHub API
>&2 echo "Requesting installation token..."
RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens")

# Debug: Print response structure without sensitive data (to stderr)
>&2 echo "Response structure:"
echo "$RESPONSE" | jq 'del(.token)' >&2

# Extract token
INSTALLATION_ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.token')

# Debug: Check if token is retrieved (to stderr)
if [[ -z "$INSTALLATION_ACCESS_TOKEN" || "$INSTALLATION_ACCESS_TOKEN" == "null" ]]; then
  >&2 echo "Error: Failed to fetch GitHub App installation token."
  >&2 echo "Response was: $RESPONSE"
  exit 1
fi

# Print ONLY the token to stdout (for capture in workflow)
echo "$INSTALLATION_ACCESS_TOKEN"
