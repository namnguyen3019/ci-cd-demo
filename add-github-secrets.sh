#!/bin/bash

# Add GitHub Secrets via CLI
# This script helps you authenticate with GitHub and add the required secrets

set -e

echo "🔐 Adding GitHub Secrets via CLI"
echo "================================"
echo ""

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI is not installed"
    echo "Please install it first:"
    echo "  macOS: brew install gh"
    echo "  Linux: https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
    exit 1
fi

echo "✅ GitHub CLI is installed"
echo ""

# Check authentication status
echo "1️⃣ Checking GitHub authentication..."
if gh auth status &> /dev/null; then
    echo "✅ Already authenticated with GitHub"
else
    echo "🔑 Need to authenticate with GitHub"
    echo ""
    echo "Please run the following command to authenticate:"
    echo "gh auth login"
    echo ""
    echo "Choose these options when prompted:"
    echo "  - What account do you want to log into? → GitHub.com"
    echo "  - What is your preferred protocol for Git operations? → HTTPS"
    echo "  - Authenticate Git with your GitHub credentials? → Yes"
    echo "  - How would you like to authenticate GitHub CLI? → Login with a web browser"
    echo ""
    read -p "Press Enter after you've completed authentication..."
    
    # Verify authentication
    if ! gh auth status &> /dev/null; then
        echo "❌ Authentication failed. Please try again."
        exit 1
    fi
    echo "✅ Successfully authenticated!"
fi

echo ""
echo "2️⃣ Getting AWS credentials..."

# Get AWS credentials
AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id 2>/dev/null || echo "")
AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key 2>/dev/null || echo "")

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "❌ AWS credentials not found in AWS CLI configuration"
    echo ""
    echo "Please ensure your AWS CLI is configured with:"
    echo "  aws configure"
    echo ""
    echo "Or set environment variables:"
    echo "  export AWS_ACCESS_KEY_ID=your_access_key"
    echo "  export AWS_SECRET_ACCESS_KEY=your_secret_key"
    exit 1
fi

echo "✅ AWS credentials found"
echo "   Access Key ID: ${AWS_ACCESS_KEY_ID:0:10}..."
echo ""

echo "3️⃣ Adding secrets to GitHub repository..."

# Add AWS_ACCESS_KEY_ID secret
echo "Adding AWS_ACCESS_KEY_ID..."
echo "$AWS_ACCESS_KEY_ID" | gh secret set AWS_ACCESS_KEY_ID

if [ $? -eq 0 ]; then
    echo "✅ AWS_ACCESS_KEY_ID added successfully"
else
    echo "❌ Failed to add AWS_ACCESS_KEY_ID"
    exit 1
fi

# Add AWS_SECRET_ACCESS_KEY secret
echo "Adding AWS_SECRET_ACCESS_KEY..."
echo "$AWS_SECRET_ACCESS_KEY" | gh secret set AWS_SECRET_ACCESS_KEY

if [ $? -eq 0 ]; then
    echo "✅ AWS_SECRET_ACCESS_KEY added successfully"
else
    echo "❌ Failed to add AWS_SECRET_ACCESS_KEY"
    exit 1
fi

echo ""
echo "4️⃣ Verifying secrets were added..."

# List secrets to verify
SECRETS_LIST=$(gh secret list 2>/dev/null || echo "")

if echo "$SECRETS_LIST" | grep -q "AWS_ACCESS_KEY_ID"; then
    echo "✅ AWS_ACCESS_KEY_ID verified in repository"
else
    echo "⚠️  AWS_ACCESS_KEY_ID not found in secrets list"
fi

if echo "$SECRETS_LIST" | grep -q "AWS_SECRET_ACCESS_KEY"; then
    echo "✅ AWS_SECRET_ACCESS_KEY verified in repository"
else
    echo "⚠️  AWS_SECRET_ACCESS_KEY not found in secrets list"
fi

echo ""
echo "🎉 GitHub Secrets Setup Complete!"
echo "================================="
echo ""
echo "📋 Added Secrets:"
echo "  ✅ AWS_ACCESS_KEY_ID"
echo "  ✅ AWS_SECRET_ACCESS_KEY"
echo ""
echo "🚀 Your CI/CD pipeline is now ready!"
echo ""
echo "Next steps:"
echo "1. Make a small change to your code"
echo "2. Commit and push to the 'main' branch:"
echo "   git add ."
echo "   git commit -m 'Trigger CI/CD pipeline'"
echo "   git push origin main"
echo "3. Watch the magic happen in GitHub Actions!"
echo ""
echo "📊 Monitor your deployment:"
echo "  - GitHub Actions: https://github.com/$(gh repo view --json owner,name -q '.owner.login + \"/\" + .name')/actions"
echo "  - AWS ECS Console: https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/todo-app-cluster"
echo ""
echo "🎊 Congratulations! Your production-ready CI/CD pipeline is now active!" 