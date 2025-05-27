#!/bin/bash

# Set variables
CLUSTER_NAME="todo-app-cluster"
REGION="us-east-1"

echo "🔄 Updating frontend with current backend URL..."

# Get backend service public IP
echo "📋 Getting backend service IP..."

# Get task ARNs for backend
backend_task_arns=$(aws ecs list-tasks \
    --cluster $CLUSTER_NAME \
    --service-name todo-backend-service \
    --desired-status RUNNING \
    --region $REGION \
    --query 'taskArns' \
    --output text)

if [ -z "$backend_task_arns" ] || [ "$backend_task_arns" = "None" ]; then
    echo "❌ No running backend tasks found"
    exit 1
fi

# Get the first task ARN
first_backend_task=$(echo $backend_task_arns | cut -d' ' -f1)

# Get network interface
backend_network_interface=$(aws ecs describe-tasks \
    --cluster $CLUSTER_NAME \
    --tasks $first_backend_task \
    --region $REGION \
    --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
    --output text)

# Get public IP
backend_public_ip=$(aws ec2 describe-network-interfaces \
    --network-interface-ids $backend_network_interface \
    --region $REGION \
    --query 'NetworkInterfaces[0].Association.PublicIp' \
    --output text)

if [ -z "$backend_public_ip" ] || [ "$backend_public_ip" = "None" ]; then
    echo "❌ Could not get backend public IP"
    exit 1
fi

echo "✅ Backend IP: $backend_public_ip"

# Update frontend task definition
echo "📝 Updating frontend task definition..."

# Create a temporary file with updated task definition
sed "s|\"value\": \"http://.*:8000\"|\"value\": \"http://$backend_public_ip:8000\"|g" \
    .aws/task-definition-frontend.json > /tmp/task-definition-frontend-updated.json

# Register the updated task definition
aws ecs register-task-definition \
    --cli-input-json file:///tmp/task-definition-frontend-updated.json \
    --region $REGION

if [ $? -eq 0 ]; then
    echo "✅ Frontend task definition updated successfully"
    
    # Update the frontend service
    echo "🔄 Updating frontend service..."
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service todo-frontend-service \
        --task-definition todo-frontend-task \
        --region $REGION
    
    if [ $? -eq 0 ]; then
        echo "✅ Frontend service updated successfully"
        echo "🌐 Frontend will be available at: http://$(aws ec2 describe-network-interfaces --network-interface-ids $(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $(aws ecs list-tasks --cluster $CLUSTER_NAME --service-name todo-frontend-service --desired-status RUNNING --region $REGION --query 'taskArns[0]' --output text) --region $REGION --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text) --region $REGION --query 'NetworkInterfaces[0].Association.PublicIp' --output text):3000"
    else
        echo "❌ Failed to update frontend service"
    fi
else
    echo "❌ Failed to update frontend task definition"
fi

# Clean up
rm -f /tmp/task-definition-frontend-updated.json 