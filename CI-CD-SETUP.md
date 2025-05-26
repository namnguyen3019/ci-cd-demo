# CI/CD Pipeline Setup Guide

This guide will help you set up a complete CI/CD pipeline for the Todo application using GitHub Actions, AWS ECS Fargate, and AWS RDS.

## 🏗️ Architecture Overview

```
GitHub Repository
    ↓ (Push to main)
GitHub Actions CI/CD
    ↓ (Build & Test)
AWS ECR (Docker Images)
    ↓ (Deploy)
AWS ECS Fargate
    ↓ (Connect to)
AWS RDS PostgreSQL
```

## 📋 Prerequisites

### AWS Resources Required
- AWS Account with appropriate permissions
- AWS CLI configured
- ECR repositories for frontend and backend
- ECS Cluster
- RDS PostgreSQL instance
- VPC with public and private subnets
- Application Load Balancer (ALB)
- IAM roles and policies

### GitHub Repository Setup
- Repository with the Todo application code
- GitHub Secrets configured

## 🔧 AWS Infrastructure Setup

### 1. Create ECR Repositories

```bash
# Create ECR repositories
aws ecr create-repository --repository-name todo-app-frontend --region us-east-1
aws ecr create-repository --repository-name todo-app-backend --region us-east-1

# Get repository URIs (save these for later)
aws ecr describe-repositories --region us-east-1
```

### 2. Create ECS Cluster

```bash
# Create ECS cluster
aws ecs create-cluster --cluster-name todo-app-cluster --region us-east-1
```

### 3. Create RDS PostgreSQL Instance

```bash
# Create DB subnet group
aws rds create-db-subnet-group \
    --db-subnet-group-name todo-db-subnet-group \
    --db-subnet-group-description "Subnet group for Todo app database" \
    --subnet-ids subnet-12345678 subnet-87654321

# Create RDS instance
aws rds create-db-instance \
    --db-instance-identifier todo-app-db \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --master-username todouser \
    --master-user-password YOUR_SECURE_PASSWORD \
    --allocated-storage 20 \
    --db-name todoapp \
    --vpc-security-group-ids sg-12345678 \
    --db-subnet-group-name todo-db-subnet-group \
    --backup-retention-period 7 \
    --storage-encrypted
```

### 4. Create IAM Roles

#### ECS Task Execution Role

```json
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
```

Attach policies:
- `AmazonECSTaskExecutionRolePolicy`
- Custom policy for Secrets Manager access

#### ECS Task Role

```json
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
```

Attach policies for ECS Exec:
- Custom policy for ECS Exec permissions

### 5. Create Secrets in AWS Secrets Manager

```bash
# Django secret key
aws secretsmanager create-secret \
    --name "todo-app/django-secret-key" \
    --description "Django secret key for Todo app" \
    --secret-string "your-super-secret-django-key"

# Database credentials
aws secretsmanager create-secret \
    --name "todo-app/db-credentials" \
    --description "Database credentials for Todo app" \
    --secret-string '{"username":"todouser","password":"YOUR_SECURE_PASSWORD"}'
```

### 6. Create CloudWatch Log Groups

```bash
# Create log groups
aws logs create-log-group --log-group-name /ecs/todo-frontend --region us-east-1
aws logs create-log-group --log-group-name /ecs/todo-backend --region us-east-1
```

## 🔐 GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

### Required Secrets

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key ID | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |

### Optional Secrets (for notifications)

| Secret Name | Description |
|-------------|-------------|
| `SLACK_WEBHOOK_URL` | Slack webhook for notifications |
| `DISCORD_WEBHOOK_URL` | Discord webhook for notifications |

## 📝 Configuration Files Update

### 1. Update Task Definitions

Replace placeholders in `.aws/task-definition-*.json`:

- `YOUR_ACCOUNT_ID` → Your AWS Account ID
- `YOUR_RDS_ENDPOINT` → Your RDS instance endpoint
- Update IAM role ARNs
- Update ECR repository URIs

### 2. Update GitHub Actions Workflow

In `.github/workflows/ci-cd.yml`, update:

- AWS region if different from `us-east-1`
- ECR repository names
- ECS cluster and service names

## 🚀 Deployment Steps

### 1. Initial ECS Services Creation

Create ECS services using AWS CLI or Console:

```bash
# Register task definitions
aws ecs register-task-definition --cli-input-json file://.aws/task-definition-backend.json
aws ecs register-task-definition --cli-input-json file://.aws/task-definition-frontend.json

# Create services
aws ecs create-service \
    --cluster todo-app-cluster \
    --service-name todo-backend-service \
    --task-definition todo-backend-task \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-12345678],securityGroups=[sg-12345678],assignPublicIp=ENABLED}"

aws ecs create-service \
    --cluster todo-app-cluster \
    --service-name todo-frontend-service \
    --task-definition todo-frontend-task \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-12345678],securityGroups=[sg-12345678],assignPublicIp=ENABLED}"
```

### 2. Configure Load Balancer

Set up an Application Load Balancer to route traffic:

- Frontend: Port 80/443 → ECS Frontend Service (Port 3000)
- Backend: `/api/*` → ECS Backend Service (Port 8000)

### 3. First Deployment

Push to the `main` branch to trigger the CI/CD pipeline:

```bash
git add .
git commit -m "Initial CI/CD setup"
git push origin main
```

## 🔍 Monitoring and Troubleshooting

### CloudWatch Logs

Monitor application logs in CloudWatch:
- Frontend logs: `/ecs/todo-frontend`
- Backend logs: `/ecs/todo-backend`

### ECS Service Health

Check ECS service status:

```bash
aws ecs describe-services --cluster todo-app-cluster --services todo-backend-service todo-frontend-service
```

### Common Issues

1. **Task fails to start**: Check CloudWatch logs for errors
2. **Health check failures**: Verify application is responding on correct ports
3. **Database connection issues**: Check security groups and RDS accessibility
4. **Image pull errors**: Verify ECR permissions and image existence

## 🔄 Pipeline Workflow

### CI Steps (Continuous Integration)
1. **Lint and Build Frontend**: ESLint, TypeScript check, Next.js build
2. **Test Backend**: Django tests with PostgreSQL
3. **Integration Tests**: Docker Compose end-to-end tests

### CD Steps (Continuous Deployment)
1. **Build and Push Images**: Docker images to ECR
2. **Deploy to ECS**: Update ECS services with new images
3. **Run Migrations**: Execute Django migrations via ECS Exec
4. **Health Checks**: Verify deployment success

## 🛡️ Security Best Practices

### Implemented Security Measures
- Non-root users in Docker containers
- Secrets stored in AWS Secrets Manager
- VPC with private subnets for database
- Security groups with minimal required access
- IAM roles with least privilege principle

### Additional Recommendations
- Enable AWS CloudTrail for audit logging
- Use AWS WAF for web application firewall
- Implement AWS Config for compliance monitoring
- Set up AWS GuardDuty for threat detection

## 📊 Cost Optimization

### Current Setup Costs (Estimated)
- ECS Fargate: ~$30-50/month (2 services, minimal resources)
- RDS t3.micro: ~$15-20/month
- ALB: ~$20/month
- ECR: ~$1-5/month (depending on image storage)

### Optimization Tips
- Use Spot instances for non-production environments
- Implement auto-scaling based on metrics
- Use reserved instances for predictable workloads
- Monitor and right-size resources regularly

## 🔧 Customization Options

### Environment-Specific Configurations
- Create separate workflows for staging/production
- Use different AWS accounts for environments
- Implement feature branch deployments
- Add manual approval steps for production

### Additional Features
- Blue/green deployments
- Canary releases
- Automated rollback on failure
- Performance testing integration
- Security scanning in pipeline

## 📚 Additional Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Django Deployment Guide](https://docs.djangoproject.com/en/stable/howto/deployment/)
- [Next.js Deployment Guide](https://nextjs.org/docs/deployment) 