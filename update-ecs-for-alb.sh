#!/bin/bash

# Update ECS Services for ALB
echo "🔄 Updating ECS Services for ALB"
echo "================================"

# Check if alb-config.txt exists
if [ ! -f "alb-config.txt" ]; then
    echo "❌ alb-config.txt not found. Run ./create-alb.sh first"
    exit 1
fi

# Load ALB configuration
source alb-config.txt

echo "📋 Using ALB configuration:"
echo "   Frontend TG: $FRONTEND_TG_ARN"
echo "   Backend TG: $BACKEND_TG_ARN"
echo ""

# Step 1: Update task definitions to work with ALB
echo "📝 Step 1: Updating task definitions..."

# Read current task definitions
BACKEND_TASK_DEF=$(cat .aws/task-definition-backend.json)
FRONTEND_TASK_DEF=$(cat .aws/task-definition-frontend.json)

# Update backend task definition for ALB
cat > .aws/task-definition-backend-alb.json << EOF
{
  "family": "todo-backend-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::533218240958:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::533218240958:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "todo-backend",
      "image": "533218240958.dkr.ecr.us-east-1.amazonaws.com/todo-app-backend:latest",
      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "environment": [
        {
          "name": "DEBUG",
          "value": "False"
        },
        {
          "name": "DATABASE_URL",
          "value": "postgresql://todouser:TodoApp2024!SecurePass@todo-app-db.c5qm0gm8yqa1.us-east-1.rds.amazonaws.com:5432/todoapp"
        }
      ],
      "secrets": [
        {
          "name": "SECRET_KEY",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:533218240958:secret:todo-app/django-secret-key"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/todo-backend",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:8000/api/todos/ || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
EOF

# Update frontend task definition for ALB
cat > .aws/task-definition-frontend-alb.json << EOF
{
  "family": "todo-frontend-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::533218240958:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::533218240958:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "todo-frontend",
      "image": "533218240958.dkr.ecr.us-east-1.amazonaws.com/todo-app-frontend:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/todo-frontend",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:3000 || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
EOF

echo "   ✅ Updated task definitions for ALB"

# Step 2: Register new task definitions
echo ""
echo "📋 Step 2: Registering updated task definitions..."

BACKEND_TASK_DEF_ARN=$(aws ecs register-task-definition \
  --cli-input-json file://.aws/task-definition-backend-alb.json \
  --region us-east-1 \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)

echo "   ✅ Backend task definition: $BACKEND_TASK_DEF_ARN"

FRONTEND_TASK_DEF_ARN=$(aws ecs register-task-definition \
  --cli-input-json file://.aws/task-definition-frontend-alb.json \
  --region us-east-1 \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)

echo "   ✅ Frontend task definition: $FRONTEND_TASK_DEF_ARN"

# Step 3: Update ECS services
echo ""
echo "🔄 Step 3: Updating ECS services to use ALB..."

# Stop current services first
echo "   Stopping current services..."
aws ecs update-service \
  --cluster todo-app-cluster \
  --service todo-backend-service \
  --desired-count 0 \
  --region us-east-1 > /dev/null

aws ecs update-service \
  --cluster todo-app-cluster \
  --service todo-frontend-service \
  --desired-count 0 \
  --region us-east-1 > /dev/null

echo "   ⏳ Waiting for services to stop..."
aws ecs wait services-stable \
  --cluster todo-app-cluster \
  --services todo-backend-service todo-frontend-service \
  --region us-east-1

# Delete old services
echo "   Deleting old services..."
aws ecs delete-service \
  --cluster todo-app-cluster \
  --service todo-backend-service \
  --region us-east-1 > /dev/null

aws ecs delete-service \
  --cluster todo-app-cluster \
  --service todo-frontend-service \
  --region us-east-1 > /dev/null

# Create new services with ALB integration
echo "   Creating new services with ALB integration..."

# Backend service with ALB
aws ecs create-service \
  --cluster todo-app-cluster \
  --service-name todo-backend-service \
  --task-definition $BACKEND_TASK_DEF_ARN \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-073c62d41f5f2f178,subnet-0ffcb129c4743a018],securityGroups=[sg-032def7bdaffd9850],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$BACKEND_TG_ARN,containerName=todo-backend,containerPort=8000" \
  --health-check-grace-period-seconds 300 \
  --region us-east-1 > /dev/null

echo "   ✅ Backend service created with ALB"

# Frontend service with ALB
aws ecs create-service \
  --cluster todo-app-cluster \
  --service-name todo-frontend-service \
  --task-definition $FRONTEND_TASK_DEF_ARN \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-073c62d41f5f2f178,subnet-0ffcb129c4743a018],securityGroups=[sg-032def7bdaffd9850],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$FRONTEND_TG_ARN,containerName=todo-frontend,containerPort=3000" \
  --health-check-grace-period-seconds 300 \
  --region us-east-1 > /dev/null

echo "   ✅ Frontend service created with ALB"

# Step 4: Wait for services to be stable
echo ""
echo "⏳ Step 4: Waiting for services to be stable..."

aws ecs wait services-stable \
  --cluster todo-app-cluster \
  --services todo-backend-service todo-frontend-service \
  --region us-east-1

echo "   ✅ Services are stable"

# Step 5: Check target group health
echo ""
echo "🏥 Step 5: Checking target group health..."

echo "   Backend target health:"
aws elbv2 describe-target-health \
  --target-group-arn $BACKEND_TG_ARN \
  --region us-east-1 \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Description]' \
  --output table

echo "   Frontend target health:"
aws elbv2 describe-target-health \
  --target-group-arn $FRONTEND_TG_ARN \
  --region us-east-1 \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Description]' \
  --output table

# Step 6: Update CI/CD pipeline
echo ""
echo "🔄 Step 6: Updating CI/CD pipeline for ALB..."

# Update GitHub Actions workflow to use new task definitions
sed -i.bak 's/task-definition-backend.json/task-definition-backend-alb.json/g' .github/workflows/ci-cd.yml
sed -i.bak 's/task-definition-frontend.json/task-definition-frontend-alb.json/g' .github/workflows/ci-cd.yml

echo "   ✅ Updated CI/CD pipeline"

# Commit changes
echo ""
echo "📦 Committing changes..."
git add .
git commit -m "Update ECS services for ALB integration"

echo ""
echo "🎊 ECS Services Updated for ALB!"
echo "==============================="
echo ""
echo "📋 Summary:"
echo "   ✅ Task definitions updated with health checks"
echo "   ✅ Services recreated with ALB integration"
echo "   ✅ Target groups configured"
echo "   ✅ CI/CD pipeline updated"
echo ""
echo "🏥 Health Check Status:"
echo "   Check target health in AWS Console or run:"
echo "   aws elbv2 describe-target-health --target-group-arn $BACKEND_TG_ARN"
echo "   aws elbv2 describe-target-health --target-group-arn $FRONTEND_TG_ARN"
echo ""
echo "🚀 Next Steps:"
echo "1. Wait 2-3 minutes for health checks to pass"
echo "2. Test your application at the ALB DNS name"
echo "3. Push changes to trigger new deployment:"
echo "   git push origin main"
echo ""
echo "📊 Monitor your services:"
echo "   🔗 https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/todo-app-cluster" 