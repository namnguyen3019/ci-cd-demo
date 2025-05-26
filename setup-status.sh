#!/bin/bash

# Setup Status Check Script
# This script shows the current status of the CI/CD infrastructure setup

echo "🎯 Todo App CI/CD Infrastructure Status"
echo "========================================"
echo ""

# Check RDS
echo "1️⃣ RDS PostgreSQL Database:"
RDS_STATUS=$(aws rds describe-db-instances --db-instance-identifier todo-app-db --region us-east-1 --query 'DBInstances[0].DBInstanceStatus' --output text 2>/dev/null || echo "NOT_FOUND")
if [ "$RDS_STATUS" = "available" ]; then
    RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier todo-app-db --region us-east-1 --query 'DBInstances[0].Endpoint.Address' --output text)
    echo "   ✅ Status: $RDS_STATUS"
    echo "   📍 Endpoint: $RDS_ENDPOINT"
else
    echo "   ❌ Status: $RDS_STATUS"
fi
echo ""

# Check ECR repositories
echo "2️⃣ ECR Repositories:"
FRONTEND_REPO=$(aws ecr describe-repositories --repository-names todo-app-frontend --region us-east-1 --query 'repositories[0].repositoryName' --output text 2>/dev/null || echo "NOT_FOUND")
BACKEND_REPO=$(aws ecr describe-repositories --repository-names todo-app-backend --region us-east-1 --query 'repositories[0].repositoryName' --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$FRONTEND_REPO" = "todo-app-frontend" ]; then
    echo "   ✅ Frontend: $FRONTEND_REPO"
else
    echo "   ❌ Frontend: NOT_FOUND"
fi

if [ "$BACKEND_REPO" = "todo-app-backend" ]; then
    echo "   ✅ Backend: $BACKEND_REPO"
else
    echo "   ❌ Backend: NOT_FOUND"
fi
echo ""

# Check ECS cluster
echo "3️⃣ ECS Cluster:"
ECS_STATUS=$(aws ecs describe-clusters --clusters todo-app-cluster --region us-east-1 --query 'clusters[0].status' --output text 2>/dev/null || echo "NOT_FOUND")
if [ "$ECS_STATUS" = "ACTIVE" ]; then
    echo "   ✅ Status: $ECS_STATUS"
else
    echo "   ❌ Status: $ECS_STATUS"
fi
echo ""

# Check CloudWatch log groups
echo "4️⃣ CloudWatch Log Groups:"
FRONTEND_LOG=$(aws logs describe-log-groups --log-group-name-prefix /ecs/todo-frontend --region us-east-1 --query 'logGroups[0].logGroupName' --output text 2>/dev/null || echo "NOT_FOUND")
BACKEND_LOG=$(aws logs describe-log-groups --log-group-name-prefix /ecs/todo-backend --region us-east-1 --query 'logGroups[0].logGroupName' --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$FRONTEND_LOG" = "/ecs/todo-frontend" ]; then
    echo "   ✅ Frontend: $FRONTEND_LOG"
else
    echo "   ❌ Frontend: NOT_FOUND"
fi

if [ "$BACKEND_LOG" = "/ecs/todo-backend" ]; then
    echo "   ✅ Backend: $BACKEND_LOG"
else
    echo "   ❌ Backend: NOT_FOUND"
fi
echo ""

# Check Secrets Manager
echo "5️⃣ AWS Secrets Manager:"
DJANGO_SECRET=$(aws secretsmanager describe-secret --secret-id todo-app/django-secret-key --region us-east-1 --query 'Name' --output text 2>/dev/null || echo "NOT_FOUND")
DB_SECRET=$(aws secretsmanager describe-secret --secret-id todo-app/db-credentials --region us-east-1 --query 'Name' --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$DJANGO_SECRET" = "todo-app/django-secret-key" ]; then
    echo "   ✅ Django Secret: Created"
else
    echo "   ❌ Django Secret: NOT_FOUND"
fi

if [ "$DB_SECRET" = "todo-app/db-credentials" ]; then
    echo "   ✅ DB Credentials: Created"
else
    echo "   ❌ DB Credentials: NOT_FOUND"
fi
echo ""

# Check task definitions
echo "6️⃣ Task Definitions:"
if [ -f ".aws/task-definition-backend.json" ]; then
    BACKEND_ACCOUNT=$(grep -o '"533218240958"' .aws/task-definition-backend.json | head -1)
    if [ "$BACKEND_ACCOUNT" = '"533218240958"' ]; then
        echo "   ✅ Backend: Updated with correct Account ID"
    else
        echo "   ❌ Backend: Needs Account ID update"
    fi
else
    echo "   ❌ Backend: File not found"
fi

if [ -f ".aws/task-definition-frontend.json" ]; then
    FRONTEND_ACCOUNT=$(grep -o '"533218240958"' .aws/task-definition-frontend.json | head -1)
    if [ "$FRONTEND_ACCOUNT" = '"533218240958"' ]; then
        echo "   ✅ Frontend: Updated with correct Account ID"
    else
        echo "   ❌ Frontend: Needs Account ID update"
    fi
else
    echo "   ❌ Frontend: File not found"
fi
echo ""

echo "🔧 REMAINING SETUP STEPS:"
echo "========================="
echo ""
echo "7️⃣ IAM Roles (Manual Setup Required):"
echo "   ❗ Create ecsTaskExecutionRole with policies:"
echo "      - AmazonECSTaskExecutionRolePolicy"
echo "      - Custom policy for Secrets Manager access"
echo ""
echo "   ❗ Create ecsTaskRole with policies:"
echo "      - Custom policy for ECS Exec permissions"
echo ""
echo "8️⃣ Security Group Configuration:"
echo "   ❗ Add inbound rule to security group sg-032def7bdaffd9850:"
echo "      - Type: PostgreSQL"
echo "      - Port: 5432"
echo "      - Source: Security group used by ECS tasks"
echo ""
echo "9️⃣ GitHub Secrets (Required for CI/CD):"
echo "   ❗ Add to your GitHub repository secrets:"
echo "      - AWS_ACCESS_KEY_ID: Your AWS access key"
echo "      - AWS_SECRET_ACCESS_KEY: Your AWS secret key"
echo ""
echo "🔟 Load Balancer (Optional but Recommended):"
echo "   ❗ Create Application Load Balancer to route traffic"
echo "   ❗ Configure target groups for ECS services"
echo ""
echo "📚 Detailed instructions available in CI-CD-SETUP.md"
echo ""
echo "🚀 Once complete, you can:"
echo "   1. Push code to main branch to trigger CI/CD"
echo "   2. Monitor deployments in GitHub Actions"
echo "   3. View logs in CloudWatch" 