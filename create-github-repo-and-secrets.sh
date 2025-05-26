#!/bin/bash

# Create GitHub Repository and Add Secrets
# This script creates a GitHub repo and adds AWS secrets

set -e

echo "🚀 Creating GitHub Repository and Adding Secrets"
echo "================================================"
echo ""

# First, let's update our commit to include the frontend properly
echo "1️⃣ Updating Git commit..."
git add .
git commit --amend -m "Initial commit: Complete CI/CD infrastructure setup

- Django backend with PostgreSQL
- Next.js frontend with Tailwind CSS  
- Docker configurations for both services
- GitHub Actions CI/CD pipeline
- AWS ECS Fargate deployment configuration
- RDS PostgreSQL database setup
- IAM roles and security groups configured
- Comprehensive testing and documentation"

echo "✅ Git commit updated"

# Create GitHub repository
echo ""
echo "2️⃣ Creating GitHub repository..."
REPO_NAME="ci-cd-demo"
REPO_DESCRIPTION="Full-stack Todo app with complete CI/CD pipeline - Django backend, Next.js frontend, deployed on AWS ECS Fargate"

gh repo create "$REPO_NAME" \
    --description "$REPO_DESCRIPTION" \
    --public \
    --source=. \
    --remote=origin \
    --push

echo "✅ GitHub repository created and code pushed"

# Add GitHub secrets
echo ""
echo "3️⃣ Adding GitHub secrets..."

# Get AWS credentials
AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id 2>/dev/null || echo "")
AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key 2>/dev/null || echo "")

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "❌ AWS credentials not found in AWS CLI configuration"
    echo "Please run: aws configure"
    exit 1
fi

echo "Adding AWS_ACCESS_KEY_ID..."
echo "$AWS_ACCESS_KEY_ID" | gh secret set AWS_ACCESS_KEY_ID

echo "Adding AWS_SECRET_ACCESS_KEY..."
echo "$AWS_SECRET_ACCESS_KEY" | gh secret set AWS_SECRET_ACCESS_KEY

echo "✅ GitHub secrets added successfully"

# Verify secrets
echo ""
echo "4️⃣ Verifying setup..."

# List secrets
SECRETS_LIST=$(gh secret list 2>/dev/null || echo "")
echo "📋 Repository secrets:"
echo "$SECRETS_LIST"

# Get repository URL
REPO_URL=$(gh repo view --json url -q '.url')

echo ""
echo "🎉 GitHub Setup Complete!"
echo "========================="
echo ""
echo "📍 Repository URL: $REPO_URL"
echo "📊 GitHub Actions: $REPO_URL/actions"
echo "🔐 Secrets: $REPO_URL/settings/secrets/actions"
echo ""
echo "✅ What's been set up:"
echo "  🌐 GitHub repository created (public)"
echo "  📤 Complete codebase pushed to GitHub"
echo "  🔑 AWS secrets added to repository"
echo "  🚀 CI/CD pipeline ready to trigger"
echo ""
echo "🎯 Your CI/CD Pipeline Will Now:"
echo "1. ✅ Lint and build frontend (Next.js)"
echo "2. ✅ Test backend with PostgreSQL"
echo "3. ✅ Run integration tests with Docker Compose"
echo "4. ✅ Build Docker images for both services"
echo "5. ✅ Push images to ECR repositories"
echo "6. ✅ Deploy to ECS Fargate services"
echo "7. ✅ Run database migrations via ECS Exec"
echo "8. ✅ Verify deployment success"
echo ""
echo "🔥 The pipeline will trigger automatically on the next push to main!"
echo ""
echo "🎊 Congratulations! Your production-ready CI/CD pipeline is now LIVE!"
echo ""
echo "📊 Monitor your deployment:"
echo "  - GitHub Actions: $REPO_URL/actions"
echo "  - AWS ECS Console: https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/todo-app-cluster" 