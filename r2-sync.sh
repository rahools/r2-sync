#!/bin/bash

# r2-sync.sh - Sync files to Cloudflare R2
# This script syncs files and subfolders to a specified R2 bucket
# Usage: ./r2-sync.sh --account-id ACCOUNT_ID --bucket BUCKET_NAME --path SOURCE_PATH
#        ./r2-sync.sh -a ACCOUNT_ID -b BUCKET_NAME -p SOURCE_PATH

# Exit on error
set -e

# Default values
R2_REGION="auto"
LOG_FILE="/var/log/r2-sync.log"
ACCESS_KEY=""
SECRET_KEY=""

# Help function
function show_help {
    echo "Usage: $0 [OPTIONS]"
    echo "Sync files to Cloudflare R2 bucket"
    echo ""
    echo "Options:"
    echo "  -a, --account-id ACCOUNT_ID   Cloudflare Account ID for R2"
    echo "  -b, --bucket BUCKET_NAME      R2 Bucket name"
    echo "  -p, --path SOURCE_PATH        Source directory path to sync"
    echo "  -l, --log-file LOG_FILE       Log file path (default: /var/log/r2-sync.log)"
    echo "  -k, --access-key ACCESS_KEY   R2 Access Key (optional, can use AWS config)"
    echo "  -s, --secret-key SECRET_KEY   R2 Secret Key (optional, can use AWS config)"
    echo "  -h, --help                    Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --account-id abc123 --bucket my-bucket --path /data/backup"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--account-id)
            ACCOUNT_ID="$2"
            shift 2
            ;;
        -b|--bucket)
            R2_BUCKET="$2"
            shift 2
            ;;
        -p|--path)
            SOURCE_DIR="$2"
            shift 2
            ;;
        -l|--log-file)
            LOG_FILE="$2"
            shift 2
            ;;
        -k|--access-key)
            ACCESS_KEY="$2"
            shift 2
            ;;
        -s|--secret-key)
            SECRET_KEY="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

# Check for required parameters
if [ -z "$ACCOUNT_ID" ] || [ -z "$R2_BUCKET" ] || [ -z "$SOURCE_DIR" ]; then
    echo "Error: Missing required parameters"
    show_help
fi

# Build R2 endpoint URL
R2_ENDPOINT="https://${ACCOUNT_ID}.r2.cloudflarestorage.com"

# Verify source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

# Make sure log directory exists
LOG_DIR=$(dirname "$LOG_FILE")
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Get timestamp
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Make sure AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed"
    echo "Please install it with: pip install awscli"
    exit 1
fi

# Log start
echo "$TIMESTAMP - Starting sync from $SOURCE_DIR to R2 bucket $R2_BUCKET" >> "$LOG_FILE"

# Set up AWS credentials if provided
AWS_ENV=""
if [ -n "$ACCESS_KEY" ] && [ -n "$SECRET_KEY" ]; then
    AWS_ENV="AWS_ACCESS_KEY_ID=$ACCESS_KEY AWS_SECRET_ACCESS_KEY=$SECRET_KEY"
fi

# Sync files to R2
# Using AWS CLI with S3 compatibility mode
if [ -n "$AWS_ENV" ]; then
    eval "$AWS_ENV aws s3 sync \"$SOURCE_DIR\" \"s3://$R2_BUCKET\" \
        --endpoint-url \"$R2_ENDPOINT\" \
        --region \"$R2_REGION\" \
        --no-progress \
        2>> \"$LOG_FILE\""
else
    aws s3 sync "$SOURCE_DIR" "s3://$R2_BUCKET" \
        --endpoint-url "$R2_ENDPOINT" \
        --region "$R2_REGION" \
        --no-progress \
        2>> "$LOG_FILE"
fi

# Check if sync was successful
if [ $? -eq 0 ]; then
    echo "$TIMESTAMP - Sync completed successfully" >> "$LOG_FILE"
    echo "Files successfully synced to R2 bucket: $R2_BUCKET"
else
    echo "$TIMESTAMP - Sync failed with error code $?" >> "$LOG_FILE"
    echo "Sync failed. Check log file for details: $LOG_FILE"
    exit 1
fi

exit 0 