#!/bin/bash

# Terraform Security Scan Script
# Usage: tf-scan.sh TYPE APP_NAME ENVIRONMENTS MODULES

set -e

TYPE=$1
APP_NAME=$2
ENVIRONMENTS=$3
MODULES=$4

echo "=== Terraform Security Scan ==="
echo "Type: $TYPE"
echo "App Name: $APP_NAME"
echo "Environment: $ENVIRONMENTS"
echo "Module: $MODULES"

# Update package lists
apt-get update

# Install required tools
echo "Installing security scanning tools..."
apt-get install -y wget unzip curl

# Install tfsec
echo "Installing tfsec..."
wget -O tfsec https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec-linux-amd64
chmod +x tfsec
mv tfsec /usr/local/bin/

# Run tfsec scan
echo "Running tfsec security scan..."
tfsec . --format json --out tfsec-results.json || true

# Display results
echo "Security scan results:"
cat tfsec-results.json

echo "=== Security Scan Complete ==="