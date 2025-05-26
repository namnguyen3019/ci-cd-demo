#!/bin/bash

# Create IAM Roles for ECS
# This script creates the required IAM roles and policies for ECS Fargate deployment

set -e

echo "🔐 Creating IAM Roles for ECS..."
echo "================================"

# Create trust policy for ECS tasks
cat > ecs-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

echo "1️⃣ Creating ECS Task Execution Role..."

# Create ecsTaskExecutionRole
aws iam create-role \
    --role-name ecsTaskExecutionRole \
    --assume-role-policy-document file://ecs-trust-policy.json \
    --description "ECS Task Execution Role for Todo App" 2>/dev/null || echo "Role may already exist"

# Attach AWS managed policy for ECS task execution
aws iam attach-role-policy \
    --role-name ecsTaskExecutionRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

echo "✅ ECS Task Execution Role created with basic policy"

# Create custom policy for Secrets Manager access
cat > secrets-manager-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-east-1:533218240958:secret:todo-app/*"
      ]
    }
  ]
}
EOF

# Create and attach Secrets Manager policy
aws iam create-policy \
    --policy-name TodoAppSecretsManagerPolicy \
    --policy-document file://secrets-manager-policy.json \
    --description "Policy for accessing Todo App secrets" 2>/dev/null || echo "Policy may already exist"

aws iam attach-role-policy \
    --role-name ecsTaskExecutionRole \
    --policy-arn arn:aws:iam::533218240958:policy/TodoAppSecretsManagerPolicy

echo "✅ Secrets Manager policy attached to Task Execution Role"

echo ""
echo "2️⃣ Creating ECS Task Role..."

# Create ecsTaskRole
aws iam create-role \
    --role-name ecsTaskRole \
    --assume-role-policy-document file://ecs-trust-policy.json \
    --description "ECS Task Role for Todo App" 2>/dev/null || echo "Role may already exist"

# Create custom policy for ECS Exec
cat > ecs-exec-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:us-east-1:533218240958:log-group:/ecs/todo-*"
      ]
    }
  ]
}
EOF

# Create and attach ECS Exec policy
aws iam create-policy \
    --policy-name TodoAppECSExecPolicy \
    --policy-document file://ecs-exec-policy.json \
    --description "Policy for ECS Exec and logging" 2>/dev/null || echo "Policy may already exist"

aws iam attach-role-policy \
    --role-name ecsTaskRole \
    --policy-arn arn:aws:iam::533218240958:policy/TodoAppECSExecPolicy

echo "✅ ECS Exec policy attached to Task Role"

echo ""
echo "3️⃣ Verifying role creation..."

# Verify roles exist
EXECUTION_ROLE_ARN=$(aws iam get-role --role-name ecsTaskExecutionRole --query 'Role.Arn' --output text 2>/dev/null || echo "NOT_FOUND")
TASK_ROLE_ARN=$(aws iam get-role --role-name ecsTaskRole --query 'Role.Arn' --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$EXECUTION_ROLE_ARN" != "NOT_FOUND" ]; then
    echo "✅ ecsTaskExecutionRole: $EXECUTION_ROLE_ARN"
else
    echo "❌ ecsTaskExecutionRole: NOT_FOUND"
fi

if [ "$TASK_ROLE_ARN" != "NOT_FOUND" ]; then
    echo "✅ ecsTaskRole: $TASK_ROLE_ARN"
else
    echo "❌ ecsTaskRole: NOT_FOUND"
fi

echo ""
echo "4️⃣ Cleaning up temporary files..."
rm -f ecs-trust-policy.json secrets-manager-policy.json ecs-exec-policy.json

echo ""
echo "🎉 IAM Roles Setup Complete!"
echo "============================"
echo "📝 Created Roles:"
echo "  - ecsTaskExecutionRole (for pulling images and accessing secrets)"
echo "  - ecsTaskRole (for ECS Exec and logging)"
echo ""
echo "📋 Attached Policies:"
echo "  - AmazonECSTaskExecutionRolePolicy (AWS managed)"
echo "  - TodoAppSecretsManagerPolicy (custom)"
echo "  - TodoAppECSExecPolicy (custom)"
echo ""
echo "🔧 Next Steps:"
echo "1. Configure security group for database access"
echo "2. Set up GitHub repository secrets"
echo "3. Test the CI/CD pipeline"
echo ""
echo "⚠️  Note: It may take a few minutes for the roles to propagate across AWS services." 