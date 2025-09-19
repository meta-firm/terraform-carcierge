#!/bin/bash

# Terraform Validation Script
# Usage: tf-validate.sh ENVIRONMENTS MODULES APP_NAME TYPE BACKEND_REGION TF_LOG

set -e

ENVIRONMENTS=$1
MODULES=$2
APP_NAME=$3
TYPE=$4
BACKEND_REGION=$5
TF_LOG=$6

echo "=== Terraform Validation ==="
echo "Environment: $ENVIRONMENTS"
echo "Module: $MODULES"
echo "App Name: $APP_NAME"
echo "Type: $TYPE"
echo "Backend Region: $BACKEND_REGION"

# Set Terraform log level if provided
if [ ! -z "$TF_LOG" ]; then
    export TF_LOG=$TF_LOG
fi

# Initialize Terraform
echo "Initializing Terraform..."
terraform init -backend=true -input=false

# Validate Terraform configuration
echo "Validating Terraform configuration..."
terraform validate

# Format check
echo "Checking Terraform formatting..."
terraform fmt -check=true -diff=true

echo "=== Validation Complete ==="