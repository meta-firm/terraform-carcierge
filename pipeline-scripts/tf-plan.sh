#!/bin/bash

# Terraform Plan Script
# Usage: tf-plan.sh ENVIRONMENTS MODULES APP_NAME TYPE BACKEND_REGION TF_LOG

set -e

ENVIRONMENTS=$1
MODULES=$2
APP_NAME=$3
TYPE=$4
BACKEND_REGION=$5
TF_LOG=$6

echo "=== Terraform Plan ==="
echo "Environment: $ENVIRONMENTS"
echo "Module: $MODULES"
echo "App Name: $APP_NAME"
echo "Type: $TYPE"
echo "Backend Region: $BACKEND_REGION"

# Set Terraform log level if provided
if [ ! -z "$TF_LOG" ]; then
    export TF_LOG=$TF_LOG
fi

# Initialize Terraform (in case not done in validate stage)
echo "Initializing Terraform..."
terraform init -backend=true -input=false

# Create Terraform plan
echo "Creating Terraform plan..."
terraform plan -input=false -out="${CI_PROJECT_DIR}/${ENVIRONMENTS}-${APP_NAME}.tfplan" -var-file="terraform.tfvars"

# Convert plan to JSON for analysis
echo "Converting plan to JSON..."
terraform show -json "${CI_PROJECT_DIR}/${ENVIRONMENTS}-${APP_NAME}.tfplan" > "${CI_PROJECT_DIR}/${ENVIRONMENTS}-${APP_NAME}.tfplan.json"

echo "=== Plan Complete ==="