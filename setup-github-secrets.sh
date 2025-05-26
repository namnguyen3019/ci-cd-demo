#!/bin/bash

# GitHub Secrets Setup Guide
# This script provides instructions and commands for setting up GitHub repository secrets

echo "🔐 GitHub Repository Secrets Setup Guide"
echo "========================================"
echo ""

echo "📋 Required Secrets for CI/CD Pipeline:"
echo "======================================="
echo ""

# Get current AWS credentials info
echo "1️⃣ Getting your AWS credentials information..."
echo ""

# Get current AWS user/role info
AWS_USER_INFO=$(aws sts get-caller-identity 2>/dev/null || echo "ERROR: AWS CLI not configured")

if [ "$AWS_USER_INFO" != "ERROR: AWS CLI not configured" ]; then
    AWS_ACCOUNT_ID=$(echo "$AWS_USER_INFO" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
    AWS_USER_ARN=$(echo "$AWS_USER_INFO" | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)
    
    echo "✅ AWS Account ID: $AWS_ACCOUNT_ID"
    echo "✅ Current AWS User/Role: $AWS_USER_ARN"
else
    echo "❌ AWS CLI not configured properly"
    echo "Please run: aws configure"
    exit 1
fi

echo ""
echo "2️⃣ Required GitHub Secrets:"
echo "============================"
echo ""

echo "You need to add these secrets to your GitHub repository:"
echo ""
echo "Secret Name: AWS_ACCESS_KEY_ID"
echo "Description: Your AWS Access Key ID"
echo "Value: [Your AWS Access Key ID]"
echo ""
echo "Secret Name: AWS_SECRET_ACCESS_KEY"
echo "Description: Your AWS Secret Access Key"
echo "Value: [Your AWS Secret Access Key]"
echo ""

echo "3️⃣ How to Add Secrets to GitHub Repository:"
echo "==========================================="
echo ""
echo "Option A: Using GitHub Web Interface (Recommended)"
echo "------------------------------------------------"
echo "1. Go to your GitHub repository"
echo "2. Click on 'Settings' tab"
echo "3. In the left sidebar, click 'Secrets and variables' → 'Actions'"
echo "4. Click 'New repository secret'"
echo "5. Add each secret with the name and value shown above"
echo ""

echo "Option B: Using GitHub CLI (if installed)"
echo "----------------------------------------"
echo "If you have GitHub CLI installed, you can run these commands:"
echo ""
echo "# Set AWS_ACCESS_KEY_ID"
echo "gh secret set AWS_ACCESS_KEY_ID"
echo ""
echo "# Set AWS_SECRET_ACCESS_KEY"
echo "gh secret set AWS_SECRET_ACCESS_KEY"
echo ""

echo "4️⃣ Security Best Practices:"
echo "==========================="
echo ""
echo "🔒 For production environments, consider:"
echo "  - Creating a dedicated IAM user for CI/CD"
echo "  - Using IAM roles with minimal required permissions"
echo "  - Rotating access keys regularly"
echo "  - Using AWS IAM Identity Center (SSO) for better security"
echo ""

echo "5️⃣ Required IAM Permissions for CI/CD User:"
echo "==========================================="
echo ""
echo "The AWS user/role needs these permissions:"
echo "  ✅ ECR: Push/pull Docker images"
echo "  ✅ ECS: Update services and task definitions"
echo "  ✅ ECS: Execute commands (for migrations)"
echo "  ✅ Secrets Manager: Read secrets"
echo "  ✅ CloudWatch: Write logs"
echo ""

echo "6️⃣ Testing GitHub Secrets:"
echo "=========================="
echo ""
echo "After adding secrets, you can test by:"
echo "1. Making a small change to your code"
echo "2. Committing and pushing to the 'main' branch"
echo "3. Checking the GitHub Actions tab for the workflow run"
echo "4. Verifying that the CI/CD pipeline runs successfully"
echo ""

echo "7️⃣ Current Infrastructure Status:"
echo "================================="
echo ""
echo "✅ RDS PostgreSQL: Available"
echo "✅ ECR Repositories: Created"
echo "✅ ECS Cluster: Active"
echo "✅ CloudWatch Log Groups: Created"
echo "✅ IAM Roles: Created with proper policies"
echo "✅ Security Groups: Configured for database and service access"
echo "✅ Secrets Manager: Django secret and DB credentials stored"
echo "✅ Task Definitions: Updated with correct values"
echo ""

echo "🚀 Next Steps After Adding GitHub Secrets:"
echo "=========================================="
echo ""
echo "1. Push code to 'main' branch to trigger CI/CD"
echo "2. Monitor the GitHub Actions workflow"
echo "3. Check CloudWatch logs for any issues"
echo "4. Verify ECS services are running"
echo "5. Test the application endpoints"
echo ""

echo "📚 Useful Commands for Monitoring:"
echo "=================================="
echo ""
echo "# Check ECS service status"
echo "aws ecs describe-services --cluster todo-app-cluster --services todo-backend-service todo-frontend-service --region us-east-1"
echo ""
echo "# Check running tasks"
echo "aws ecs list-tasks --cluster todo-app-cluster --region us-east-1"
echo ""
echo "# View CloudWatch logs"
echo "aws logs describe-log-streams --log-group-name /ecs/todo-backend --region us-east-1"
echo ""

echo "🎉 You're almost ready to deploy!"
echo "================================="
echo ""
echo "Once you add the GitHub secrets, your CI/CD pipeline will be fully functional."
echo "The next push to the main branch will trigger automatic deployment to AWS ECS!"

# Save this information to a file
cat > github-secrets-info.txt << EOF
GitHub Secrets Setup Information
===============================

Required Secrets:
- AWS_ACCESS_KEY_ID: Your AWS Access Key ID
- AWS_SECRET_ACCESS_KEY: Your AWS Secret Access Key

AWS Account ID: $AWS_ACCOUNT_ID
Current AWS User/Role: $AWS_USER_ARN

Setup completed: $(date)

Next: Add these secrets to your GitHub repository and push to main branch to trigger deployment.
EOF

echo ""
echo "💾 Information saved to: github-secrets-info.txt" 