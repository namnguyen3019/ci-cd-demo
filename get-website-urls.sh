#!/bin/bash

# Get Website URLs Script
# This script automatically finds and displays your website access URLs

echo "🌐 Finding Your Todo Website URLs"
echo "================================="
echo ""

# Check if services exist
echo "1️⃣ Checking ECS services status..."
SERVICES_STATUS=$(aws ecs describe-services --cluster todo-app-cluster --services todo-backend-service todo-frontend-service --region us-east-1 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "❌ Services not found. Checking deployment status..."
    echo ""
    
    # Check GitHub Actions
    echo "🔍 GitHub Actions Status:"
    echo "Repository: https://github.com/namnguyen3019/ci-cd-demo"
    echo "Actions: https://github.com/namnguyen3019/ci-cd-demo/actions"
    echo ""
    
    echo "📋 Next Steps:"
    echo "1. Check GitHub Actions to see if deployment is running"
    echo "2. If no workflow is running, trigger deployment:"
    echo "   echo '# Trigger deployment' >> README.md"
    echo "   git add README.md && git commit -m 'Trigger deployment' && git push origin main"
    echo "3. Wait 15-25 minutes for first deployment to complete"
    echo "4. Run this script again: ./get-website-urls.sh"
    exit 1
fi

# Parse service status
BACKEND_STATUS=$(echo "$SERVICES_STATUS" | grep -A 10 "todo-backend-service" | grep '"status"' | cut -d'"' -f4)
FRONTEND_STATUS=$(echo "$SERVICES_STATUS" | grep -A 10 "todo-frontend-service" | grep '"status"' | cut -d'"' -f4)
BACKEND_RUNNING=$(echo "$SERVICES_STATUS" | grep -A 10 "todo-backend-service" | grep '"runningCount"' | grep -o '[0-9]*')
FRONTEND_RUNNING=$(echo "$SERVICES_STATUS" | grep -A 10 "todo-frontend-service" | grep '"runningCount"' | grep -o '[0-9]*')

echo "✅ Services found!"
echo "   Backend: $BACKEND_STATUS (Running: $BACKEND_RUNNING)"
echo "   Frontend: $FRONTEND_STATUS (Running: $FRONTEND_RUNNING)"
echo ""

if [ "$BACKEND_RUNNING" = "0" ] && [ "$FRONTEND_RUNNING" = "0" ]; then
    echo "⏳ Services exist but no tasks are running yet."
    echo "   This usually means deployment is in progress."
    echo "   Wait a few minutes and try again."
    echo ""
    echo "📊 Monitor deployment:"
    echo "   GitHub Actions: https://github.com/namnguyen3019/ci-cd-demo/actions"
    echo "   AWS ECS: https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/todo-app-cluster"
    exit 1
fi

echo "2️⃣ Getting running tasks..."

# Get running tasks
TASKS=$(aws ecs list-tasks --cluster todo-app-cluster --region us-east-1 --query 'taskArns' --output text)

if [ -z "$TASKS" ] || [ "$TASKS" = "None" ]; then
    echo "❌ No running tasks found."
    echo "   Services exist but tasks haven't started yet."
    echo "   Check ECS console for task status and logs."
    exit 1
fi

echo "✅ Found running tasks"
echo ""

echo "3️⃣ Getting public IP addresses..."

# Function to get public IP for a task
get_public_ip() {
    local task_arn=$1
    local service_name=$2
    
    # Get network interface ID
    ENI_ID=$(aws ecs describe-tasks \
        --cluster todo-app-cluster \
        --tasks "$task_arn" \
        --region us-east-1 \
        --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
        --output text 2>/dev/null)
    
    if [ -n "$ENI_ID" ] && [ "$ENI_ID" != "None" ]; then
        # Get public IP
        PUBLIC_IP=$(aws ec2 describe-network-interfaces \
            --network-interface-ids "$ENI_ID" \
            --region us-east-1 \
            --query 'NetworkInterfaces[0].Association.PublicIp' \
            --output text 2>/dev/null)
        
        if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "None" ]; then
            echo "$PUBLIC_IP"
        else
            echo "NO_PUBLIC_IP"
        fi
    else
        echo "NO_ENI"
    fi
}

# Get task details and find IPs
BACKEND_IP=""
FRONTEND_IP=""

for task in $TASKS; do
    # Get task definition ARN to determine service type
    TASK_DEF=$(aws ecs describe-tasks \
        --cluster todo-app-cluster \
        --tasks "$task" \
        --region us-east-1 \
        --query 'tasks[0].taskDefinitionArn' \
        --output text 2>/dev/null)
    
    if echo "$TASK_DEF" | grep -q "backend"; then
        BACKEND_IP=$(get_public_ip "$task" "backend")
        echo "   🔧 Backend IP: $BACKEND_IP"
    elif echo "$TASK_DEF" | grep -q "frontend"; then
        FRONTEND_IP=$(get_public_ip "$task" "frontend")
        echo "   🎨 Frontend IP: $FRONTEND_IP"
    fi
done

echo ""
echo "🎉 Your Todo Website URLs"
echo "========================="
echo ""

if [ -n "$FRONTEND_IP" ] && [ "$FRONTEND_IP" != "NO_PUBLIC_IP" ] && [ "$FRONTEND_IP" != "NO_ENI" ]; then
    echo "🌐 **Todo Application (Frontend)**"
    echo "   URL: http://$FRONTEND_IP:3000"
    echo "   Description: Main Todo app interface"
    echo ""
else
    echo "❌ Frontend not accessible yet"
fi

if [ -n "$BACKEND_IP" ] && [ "$BACKEND_IP" != "NO_PUBLIC_IP" ] && [ "$BACKEND_IP" != "NO_ENI" ]; then
    echo "🔧 **API Backend (Django REST API)**"
    echo "   URL: http://$BACKEND_IP:8000"
    echo "   API Endpoints:"
    echo "     • http://$BACKEND_IP:8000/api/todos/ (List/Create todos)"
    echo "     • http://$BACKEND_IP:8000/admin/ (Django admin)"
    echo ""
else
    echo "❌ Backend not accessible yet"
fi

echo "📱 **Quick Test Commands**"
echo "========================="
echo ""

if [ -n "$BACKEND_IP" ] && [ "$BACKEND_IP" != "NO_PUBLIC_IP" ]; then
    echo "# Test API endpoint"
    echo "curl http://$BACKEND_IP:8000/api/todos/"
    echo ""
fi

if [ -n "$FRONTEND_IP" ] && [ "$FRONTEND_IP" != "NO_PUBLIC_IP" ]; then
    echo "# Open frontend in browser"
    echo "open http://$FRONTEND_IP:3000"
    echo ""
fi

echo "📊 **Monitoring**"
echo "================"
echo "• GitHub Actions: https://github.com/namnguyen3019/ci-cd-demo/actions"
echo "• AWS ECS Console: https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/todo-app-cluster"
echo "• CloudWatch Logs: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups"
echo ""

if [ -z "$FRONTEND_IP" ] || [ "$FRONTEND_IP" = "NO_PUBLIC_IP" ] || [ -z "$BACKEND_IP" ] || [ "$BACKEND_IP" = "NO_PUBLIC_IP" ]; then
    echo "⚠️  **Note**: Some services don't have public IPs yet."
    echo "   This is normal during initial deployment."
    echo "   Wait a few minutes and run this script again."
    echo ""
    echo "🔄 **Refresh command**: ./get-website-urls.sh"
fi 