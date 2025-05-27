#!/bin/bash

# Set variables
CLUSTER_NAME="todo-app-cluster"
REGION="us-east-1"
ACCOUNT_ID="533218240958"

# Get VPC and subnet information
VPC_ID="vpc-0e2f1b8db99202357"
SUBNET_1="subnet-073c62d41f5f2f178"
SUBNET_2="subnet-0ffcb129c4743a018"
SECURITY_GROUP="sg-032def7bdaffd9850"

echo "Creating ECS services..."

# Create backend service
echo "Creating backend service..."
aws ecs create-service \
    --cluster $CLUSTER_NAME \
    --service-name todo-backend-service \
    --task-definition todo-backend-task \
    --desired-count 1 \
    --launch-type FARGATE \
    --platform-version LATEST \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_1,$SUBNET_2],securityGroups=[$SECURITY_GROUP],assignPublicIp=ENABLED}" \
    --enable-execute-command \
    --region $REGION

if [ $? -eq 0 ]; then
    echo "✅ Backend service created successfully"
else
    echo "❌ Failed to create backend service"
fi

# Wait a moment before creating the next service
sleep 5

# Create frontend service
echo "Creating frontend service..."
aws ecs create-service \
    --cluster $CLUSTER_NAME \
    --service-name todo-frontend-service \
    --task-definition todo-frontend-task \
    --desired-count 1 \
    --launch-type FARGATE \
    --platform-version LATEST \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_1,$SUBNET_2],securityGroups=[$SECURITY_GROUP],assignPublicIp=ENABLED}" \
    --enable-execute-command \
    --region $REGION

if [ $? -eq 0 ]; then
    echo "✅ Frontend service created successfully"
else
    echo "❌ Failed to create frontend service"
fi

echo "ECS services creation completed!"
echo ""
echo "You can check the services with:"
echo "aws ecs list-services --cluster $CLUSTER_NAME --region $REGION" 