# scripts/update-cloudfront.sh
#!/usr/bin/env bash

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
DIST_CONFIG_OLD_FILENAME="dist-config.json"
DIST_CONFIG_NEW_FILENAME="dist-config2.json"

# Validate environment variables
if [ -z "${CLOUDFRONT_DISTRIBUTION_ID:-}" ]; then
    echo "Error: CLOUDFRONT_DISTRIBUTION_ID is not set"
    exit 1
fi

if [ -z "${NEW_VERSION:-}" ]; then
    echo "Error: NEW_VERSION is not set"
    exit 1
fi

# Format the origin path
NEW_ORIGIN_PATH="/${NEW_VERSION}"

# Log start of execution
echo "📦 Updating to version: ${NEW_VERSION}"
echo "🔧 Distribution ID: ${CLOUDFRONT_DISTRIBUTION_ID}"

# Create Python script for JSON manipulation
cat << 'EOF' > update_config.py
import json
import sys
import os
from datetime import datetime

def log_message(message):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"{timestamp} - {message}")

try:
    # Get command line arguments
    target_origin_id = sys.argv[1]
    new_origin_path = sys.argv[2]
    input_file = sys.argv[3]
    output_file = sys.argv[4]

    # Read JSON from file
    with open(input_file, 'r') as f:
        config = json.load(f)

    # Track if we found and updated the origin
    origin_found = False

    # Update the origin path for the specified origin
    for origin in config['Distribution']['DistributionConfig']['Origins']['Items']:
        if origin['Id'] == target_origin_id:
            old_path = origin.get('OriginPath', 'none')
            origin['OriginPath'] = new_origin_path
            origin_found = True
            log_message(f"Updated origin path from {old_path} to {new_origin_path}")

    if not origin_found:
        raise ValueError(f"Origin ID '{target_origin_id}' not found in configuration")

    # Extract ETag
    etag = config.get('ETag', '')
    if not etag:
        raise ValueError("ETag not found in configuration")

    # Create new config with just DistributionConfig
    new_config = config['Distribution']['DistributionConfig']

    # Write updated config to new file
    with open(output_file, 'w') as f:
        json.dump(new_config, f, indent=2)

    # Print ETag for use in bash script
    print(etag.strip('"'))

except Exception as e:
    log_message(f"Error: {str(e)}")
    sys.exit(1)
EOF

# Function for logging
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function for cleanup
cleanup() {
    log_message "🧹 Cleaning up temporary files"
    rm -f "$DIST_CONFIG_OLD_FILENAME" "$DIST_CONFIG_NEW_FILENAME" "update_config.py"
}

# Set trap for cleanup
trap cleanup EXIT

# Main execution
try_update() {
    # 1) Get the current config
    log_message "📥 Fetching current CloudFront configuration"
    if ! aws cloudfront get-distribution --id "$CLOUDFRONT_DISTRIBUTION_ID" > "$DIST_CONFIG_OLD_FILENAME"; then
        log_message "❌ Failed to fetch CloudFront configuration"
        return 1
    fi

    # 2 & 3) Update config and get ETag using Python script
    log_message "🔄 Updating configuration"
    ETAG=$(python3 update_config.py "$CLOUDFRONT_ORIGIN_ID" "$NEW_ORIGIN_PATH" "$DIST_CONFIG_OLD_FILENAME" "$DIST_CONFIG_NEW_FILENAME")

    if [ -z "$ETAG" ]; then
        log_message "❌ Failed to get ETag from configuration"
        return 1
    fi

    log_message "🏷️ Using ETag: $ETAG"

    # 4) Update the distribution with the new file
    log_message "📤 Updating CloudFront distribution"
    if ! aws cloudfront update-distribution \
        --id "$CLOUDFRONT_DISTRIBUTION_ID" \
        --distribution-config "file://${DIST_CONFIG_NEW_FILENAME}" \
        --if-match "$ETAG"; then
        log_message "❌ Failed to update CloudFront distribution"
        return 1
    fi

    # 5) Create invalidation
    log_message "🔄 Creating cache invalidation"
    if ! aws cloudfront create-invalidation \
        --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
        --paths "/*"; then
        log_message "⚠️ Warning: Failed to create invalidation"
    fi

    return 0
}

try_update()
