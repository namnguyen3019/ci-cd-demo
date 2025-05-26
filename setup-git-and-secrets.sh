#!/bin/bash

# Setup Git Repository and GitHub Secrets
# This script initializes Git, creates a GitHub repo, and adds secrets

set -e

echo "🚀 Setting up Git Repository and GitHub Secrets"
echo "==============================================="
echo ""

# Initialize Git repository
echo "1️⃣ Initializing Git repository..."
git init
echo "✅ Git repository initialized"

# Create .gitignore if it doesn't exist
if [ ! -f .gitignore ]; then
    echo "📝 Creating .gitignore..."
    cat > .gitignore << 'EOF'
# Dependencies
node_modules/
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
env/
venv/
.venv/
pip-log.txt
pip-delete-this-directory.txt

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Logs
*.log
logs/

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Build outputs
dist/
build/
.next/
out/

# Database
*.db
*.sqlite
*.sqlite3

# AWS and secrets (just in case)
*.pem
*.key
aws-credentials.txt
rds-config.txt
github-secrets-info.txt

# Temporary files
*.tmp
*.temp
.cache/

# Coverage reports
coverage/
.nyc_output/
.coverage
htmlcov/

# Docker
.dockerignore
EOF
    echo "✅ .gitignore created"
fi

# Add all files to Git
echo ""
echo "2️⃣ Adding files to Git..."
git add .
git commit -m "Initial commit: Complete CI/CD infrastructure setup

- Django backend with PostgreSQL
- Next.js frontend with Tailwind CSS
- Docker configurations for both services
- GitHub Actions CI/CD pipeline
- AWS ECS Fargate deployment configuration
- RDS PostgreSQL database setup
- IAM roles and security groups configured
- Comprehensive testing and documentation"

echo "✅ Initial commit created"

# Create GitHub repository
echo ""
echo "3️⃣ Creating GitHub repository..."
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
echo "4️⃣ Adding GitHub secrets..."

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
echo "5️⃣ Verifying setup..."

# List secrets
SECRETS_LIST=$(gh secret list 2>/dev/null || echo "")
echo "📋 Repository secrets:"
echo "$SECRETS_LIST"

# Get repository URL
REPO_URL=$(gh repo view --json url -q '.url')

echo ""
echo "🎉 Complete Setup Successful!"
echo "============================"
echo ""
echo "📍 Repository URL: $REPO_URL"
echo "📊 GitHub Actions: $REPO_URL/actions"
echo "🔐 Secrets: $REPO_URL/settings/secrets/actions"
echo ""
echo "✅ What's been set up:"
echo "  🗂️  Git repository initialized"
echo "  🌐 GitHub repository created (public)"
echo "  📤 Code pushed to GitHub"
echo "  🔑 AWS secrets added to repository"
echo "  🚀 CI/CD pipeline ready to trigger"
echo ""
echo "🎯 Next Steps:"
echo "1. Your CI/CD pipeline will trigger automatically on the next push to main"
echo "2. Monitor the deployment: $REPO_URL/actions"
echo "3. Check AWS ECS console: https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/todo-app-cluster"
echo ""
echo "🔥 To trigger the pipeline now, make a small change and push:"
echo "   echo '# Todo App with CI/CD' >> README.md"
echo "   git add README.md"
echo "   git commit -m 'Update README - trigger CI/CD'"
echo "   git push origin main"
echo ""
echo "🎊 Congratulations! Your production-ready CI/CD pipeline is now live!" 