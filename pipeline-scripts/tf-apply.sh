#!/bin/bash

# Terraform Apply Script
# Usage: tf-apply.sh ENVIRONMENTS MODULES APP_NAME TYPE BACKEND_REGION TF_LOG

set -e

ENVIRONMENTS=$1
MODULES=$2
APP_NAME=$3
TYPE=$4
BACKEND_REGION=$5
TF_LOG=$6

echo "=== Terraform Apply ==="
echo "Environment: $ENVIRONMENTS"
echo "Module: $MODULES"
echo "App Name: $APP_NAME"
echo "Type: $TYPE"
echo "Backend Region: $BACKEND_REGION"

# Set Terraform log level if provided
if [ ! -z "$TF_LOG" ]; then
    export TF_LOG=$TF_LOG
fi

# Initialize Terraform (in case not done in previous stages)
echo "Initializing Terraform..."
terraform init -backend=true -input=false

# Apply the plan
echo "Applying Terraform plan..."
terraform apply -input=false "${CI_PROJECT_DIR}/${ENVIRONMENTS}-${APP_NAME}.tfplan"

echo "=== Apply Complete ==="