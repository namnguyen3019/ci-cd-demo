#!/bin/bash

# Set variables
CLUSTER_NAME="todo-app-cluster"
REGION="us-east-1"

echo "🔍 Getting service URLs..."
echo "================================"

# Function to get public IP for a service
get_service_info() {
    local service_name=$1
    local port=$2
    local service_type=$3
    
    echo "📋 Getting info for $service_type service..."
    
    # Get task ARNs
    task_arns=$(aws ecs list-tasks \
        --cluster $CLUSTER_NAME \
        --service-name $service_name \
        --desired-status RUNNING \
        --region $REGION \
        --query 'taskArns' \
        --output text)
    
    if [ -z "$task_arns" ] || [ "$task_arns" = "None" ]; then
        echo "❌ No running tasks found for $service_name"
        return
    fi
    
    # Get the first task ARN
    first_task=$(echo $task_arns | cut -d' ' -f1)
    
    # Get task details including network interface
    network_interface=$(aws ecs describe-tasks \
        --cluster $CLUSTER_NAME \
        --tasks $first_task \
        --region $REGION \
        --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
        --output text)
    
    if [ -z "$network_interface" ] || [ "$network_interface" = "None" ]; then
        echo "❌ Could not find network interface for $service_name"
        return
    fi
    
    # Get public IP from network interface
    public_ip=$(aws ec2 describe-network-interfaces \
        --network-interface-ids $network_interface \
        --region $REGION \
        --query 'NetworkInterfaces[0].Association.PublicIp' \
        --output text)
    
    if [ -z "$public_ip" ] || [ "$public_ip" = "None" ]; then
        echo "❌ No public IP found for $service_name"
        return
    fi
    
    echo "✅ $service_type Service:"
    echo "   Public IP: $public_ip"
    echo "   URL: http://$public_ip:$port"
    echo ""
}

# Get frontend service info
get_service_info "todo-frontend-service" "3000" "Frontend"

# Get backend service info  
get_service_info "todo-backend-service" "8000" "Backend"

echo "🌐 Access Information:"
echo "================================"
echo "Frontend (Next.js): Access the main website"
echo "Backend (Django): API endpoints and admin interface"
echo ""
echo "📝 Notes:"
echo "- Make sure your security group allows inbound traffic on ports 3000 and 8000"
echo "- If you can't access the services, check the ECS task logs for any startup issues"
echo "- The backend API will be available at: http://[backend-ip]:8000/api/todos/"
echo "- The Django admin will be available at: http://[backend-ip]:8000/admin/" 