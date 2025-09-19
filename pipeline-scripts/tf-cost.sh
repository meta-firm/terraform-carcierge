#!/bin/bash

# Terraform Cost Analysis Script
# Usage: tf-cost.sh TYPE APP_NAME ENVIRONMENTS MODULES

set -e

TYPE=$1
APP_NAME=$2
ENVIRONMENTS=$3
MODULES=$4

echo "=== Terraform Cost Analysis ==="
echo "Type: $TYPE"
echo "App Name: $APP_NAME"
echo "Environment: $ENVIRONMENTS"
echo "Module: $MODULES"

# Update package lists
apt-get update

# Install required tools
echo "Installing cost analysis tools..."
apt-get install -y wget curl jq

# Install Infracost
echo "Installing Infracost..."
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

# Run cost analysis
echo "Running cost analysis..."
if [ -f "${CI_PROJECT_DIR}/${ENVIRONMENTS}-${APP_NAME}.tfplan.json" ]; then
    /usr/local/bin/infracost breakdown --path "${CI_PROJECT_DIR}/${ENVIRONMENTS}-${APP_NAME}.tfplan.json" --format json --out infracost-results.json || true
    
    # Display results
    echo "Cost analysis results:"
    cat infracost-results.json | jq '.'
else
    echo "No plan file found for cost analysis"
fi

echo "=== Cost Analysis Complete ==="