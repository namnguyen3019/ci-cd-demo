#!/bin/bash

# Monitor Deployment Script
# This script helps you monitor your CI/CD pipeline and deployment

echo "🎯 Todo App CI/CD Pipeline - Monitoring Dashboard"
echo "================================================="
echo ""

# Get repository info
REPO_URL="https://github.com/namnguyen3019/ci-cd-demo"

echo "📊 **MONITORING LINKS**"
echo "======================"
echo ""
echo "🔗 Repository: $REPO_URL"
echo "🚀 GitHub Actions: $REPO_URL/actions"
echo "🔐 Secrets: $REPO_URL/settings/secrets/actions"
echo "📋 Workflow File: $REPO_URL/blob/main/.github/workflows/ci-cd.yml"
echo ""

echo "☁️  **AWS CONSOLE LINKS**"
echo "========================"
echo ""
echo "🗄️  RDS Database: https://console.aws.amazon.com/rds/home?region=us-east-1#database:id=todo-app-db"
echo "🐳 ECS Cluster: https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/todo-app-cluster"
echo "📦 ECR Repositories: https://console.aws.amazon.com/ecr/repositories?region=us-east-1"
echo "📊 CloudWatch Logs: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups"
echo "🔑 Secrets Manager: https://console.aws.amazon.com/secretsmanager/home?region=us-east-1"
echo ""

echo "🔍 **MONITORING COMMANDS**"
echo "========================="
echo ""
echo "# Check GitHub Actions workflow runs"
echo "gh run list --limit 5"
echo ""
echo "# Watch a specific workflow run (replace RUN_ID)"
echo "gh run watch RUN_ID"
echo ""
echo "# Check ECS service status"
echo "aws ecs describe-services --cluster todo-app-cluster --services todo-backend-service todo-frontend-service --region us-east-1"
echo ""
echo "# List running ECS tasks"
echo "aws ecs list-tasks --cluster todo-app-cluster --region us-east-1"
echo ""
echo "# Check backend logs"
echo "aws logs describe-log-streams --log-group-name /ecs/todo-backend --region us-east-1 --order-by LastEventTime --descending --max-items 5"
echo ""
echo "# Check frontend logs"
echo "aws logs describe-log-streams --log-group-name /ecs/todo-frontend --region us-east-1 --order-by LastEventTime --descending --max-items 5"
echo ""

echo "🎯 **DEPLOYMENT PIPELINE STAGES**"
echo "================================="
echo ""
echo "Your CI/CD pipeline will go through these stages:"
echo ""
echo "1. 🧪 **CI Phase (Testing)**"
echo "   ├── Lint and build frontend (Next.js)"
echo "   ├── Test backend with PostgreSQL"
echo "   └── Integration tests with Docker Compose"
echo ""
echo "2. 🏗️  **Build Phase**"
echo "   ├── Build Docker images"
echo "   └── Push to ECR repositories"
echo ""
echo "3. 🚀 **Deploy Phase**"
echo "   ├── Update ECS task definitions"
echo "   ├── Deploy to ECS Fargate"
echo "   ├── Run database migrations"
echo "   └── Verify deployment"
echo ""

echo "⏱️  **EXPECTED TIMELINE**"
echo "========================"
echo ""
echo "• CI Phase: ~5-8 minutes"
echo "• Build Phase: ~3-5 minutes"
echo "• Deploy Phase: ~5-10 minutes"
echo "• **Total: ~15-25 minutes**"
echo ""

echo "🎊 **SUCCESS INDICATORS**"
echo "========================="
echo ""
echo "✅ Pipeline completed successfully when:"
echo "   • All GitHub Actions jobs show green checkmarks"
echo "   • ECS services show 'RUNNING' status"
echo "   • Tasks are healthy and passing health checks"
echo "   • Application responds to health check endpoints"
echo ""

echo "🔧 **TROUBLESHOOTING**"
echo "======================"
echo ""
echo "If something goes wrong:"
echo "1. Check GitHub Actions logs for detailed error messages"
echo "2. Verify AWS resources are properly configured"
echo "3. Check CloudWatch logs for runtime issues"
echo "4. Ensure all secrets are correctly set"
echo ""

echo "📱 **QUICK STATUS CHECK**"
echo "========================"
echo ""

# Quick status check
echo "🔍 Current AWS Infrastructure Status:"
echo ""

# Check RDS
RDS_STATUS=$(aws rds describe-db-instances --db-instance-identifier todo-app-db --region us-east-1 --query 'DBInstances[0].DBInstanceStatus' --output text 2>/dev/null || echo "ERROR")
echo "   📊 RDS Database: $RDS_STATUS"

# Check ECS Cluster
ECS_STATUS=$(aws ecs describe-clusters --clusters todo-app-cluster --region us-east-1 --query 'clusters[0].status' --output text 2>/dev/null || echo "ERROR")
echo "   🐳 ECS Cluster: $ECS_STATUS"

# Check if services exist (they might not exist yet if this is the first deployment)
BACKEND_SERVICE=$(aws ecs describe-services --cluster todo-app-cluster --services todo-backend-service --region us-east-1 --query 'services[0].status' --output text 2>/dev/null || echo "NOT_CREATED_YET")
FRONTEND_SERVICE=$(aws ecs describe-services --cluster todo-app-cluster --services todo-frontend-service --region us-east-1 --query 'services[0].status' --output text 2>/dev/null || echo "NOT_CREATED_YET")

echo "   🔧 Backend Service: $BACKEND_SERVICE"
echo "   🎨 Frontend Service: $FRONTEND_SERVICE"

echo ""
echo "🎉 **CONGRATULATIONS!**"
echo "======================"
echo ""
echo "You have successfully created a production-ready CI/CD pipeline!"
echo "Your application will be automatically deployed to AWS ECS Fargate."
echo ""
echo "🌟 **What you've built:**"
echo "   • Full-stack Todo application"
echo "   • Automated testing and deployment"
echo "   • Cloud-native infrastructure"
echo "   • Enterprise-grade security"
echo "   • Comprehensive monitoring"
echo ""
echo "🚀 **Your application will be live soon!**"
echo ""
echo "Monitor the progress at: $REPO_URL/actions" 