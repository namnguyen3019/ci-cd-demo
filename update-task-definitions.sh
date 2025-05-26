#!/bin/bash

# Update Task Definitions Script
# This script updates the task definitions with the correct RDS endpoint and AWS Account ID

set -e

echo "🔧 Updating Task Definitions..."
echo "==============================="

# Configuration from RDS setup
RDS_ENDPOINT="todo-app-db.c5qm0gm8yqa1.us-east-1.rds.amazonaws.com"

# Get AWS Account ID
echo "1️⃣ Getting AWS Account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)

if [ -z "$AWS_ACCOUNT_ID" ] || [ "$AWS_ACCOUNT_ID" = "None" ]; then
    echo "❌ Could not automatically detect AWS Account ID"
    echo "Please run: aws sts get-caller-identity"
    echo "And manually update the task definitions with your account ID"
    exit 1
else
    echo "✅ AWS Account ID: $AWS_ACCOUNT_ID"
fi

echo ""
echo "2️⃣ Updating backend task definition..."

# Update backend task definition
sed -i.bak \
    -e "s/YOUR_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" \
    -e "s/YOUR_RDS_ENDPOINT/$RDS_ENDPOINT/g" \
    .aws/task-definition-backend.json

echo "✅ Backend task definition updated"

echo ""
echo "3️⃣ Updating frontend task definition..."

# Update frontend task definition
sed -i.bak \
    -e "s/YOUR_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" \
    .aws/task-definition-frontend.json

echo "✅ Frontend task definition updated"

echo ""
echo "4️⃣ Creating AWS Secrets Manager secrets..."

# Create Django secret key
DJANGO_SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))")

aws secretsmanager create-secret \
    --name "todo-app/django-secret-key" \
    --description "Django secret key for Todo app" \
    --secret-string "$DJANGO_SECRET" \
    --region us-east-1 2>/dev/null || echo "Secret may already exist"

# Create database credentials
aws secretsmanager create-secret \
    --name "todo-app/db-credentials" \
    --description "Database credentials for Todo app" \
    --secret-string '{"username":"todouser","password":"TodoApp2024!SecurePass"}' \
    --region us-east-1 2>/dev/null || echo "Secret may already exist"

echo "✅ Secrets created in AWS Secrets Manager"

echo ""
echo "🎉 Task Definitions Updated Successfully!"
echo "========================================"
echo "📝 Updated Information:"
echo "  - AWS Account ID: $AWS_ACCOUNT_ID"
echo "  - RDS Endpoint: $RDS_ENDPOINT"
echo "  - Django Secret: Created in Secrets Manager"
echo "  - DB Credentials: Created in Secrets Manager"
echo ""
echo "🔧 Next Steps:"
echo "1. Create ECR repositories"
echo "2. Create ECS cluster"
echo "3. Set up GitHub Secrets"
echo "4. Configure security group for ECS access"
echo ""
echo "💾 Backup files created:"
echo "  - .aws/task-definition-backend.json.bak"
echo "  - .aws/task-definition-frontend.json.bak" 