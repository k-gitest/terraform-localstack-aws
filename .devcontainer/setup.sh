#!/bin/bash
set -e
echo "Starting LocalStack in background…"
localstack start -d
echo "create backend s3 backet..."
awslocal s3 mb s3://terraform-state-local
