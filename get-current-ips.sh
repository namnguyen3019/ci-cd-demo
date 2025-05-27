#!/bin/bash

echo "🔍 Getting your Todo app's current public IPs..."
echo "================================================"

# Check if services exist
echo "📋 Checking ECS services status..."
aws ecs describe-services \
  --cluster todo-app-cluster \
  --services todo-backend-service todo-frontend-service \
  --region us-east-1 \
  --query 'services[*].[serviceName,status,runningCount]' \
  --output table

echo ""
echo "🔍 Getting public IPs..."

# Get backend IP
echo "🔧 Backend Service:"
BACKEND_TASKS=$(aws ecs list-tasks --cluster todo-app-cluster --service-name todo-backend-service --region us-east-1 --query 'taskArns[0]' --output text)

if [ "$BACKEND_TASKS" != "None" ] && [ "$BACKEND_TASKS" != "" ]; then
    BACKEND_ENI=$(aws ecs describe-tasks \
      --cluster todo-app-cluster \
      --tasks $BACKEND_TASKS \
      --region us-east-1 \
      --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
      --output text)
    
    BACKEND_IP=$(aws ec2 describe-network-interfaces \
      --network-interface-ids $BACKEND_ENI \
      --region us-east-1 \
      --query 'NetworkInterfaces[0].Association.PublicIp' \
      --output text)
    
    echo "   IP: $BACKEND_IP"
    echo "   URL: http://$BACKEND_IP:8000"
    echo "   API: http://$BACKEND_IP:8000/api/todos/"
else
    echo "   ❌ No running backend tasks found"
fi

echo ""

# Get frontend IP
echo "🎨 Frontend Service:"
FRONTEND_TASKS=$(aws ecs list-tasks --cluster todo-app-cluster --service-name todo-frontend-service --region us-east-1 --query 'taskArns[0]' --output text)

if [ "$FRONTEND_TASKS" != "None" ] && [ "$FRONTEND_TASKS" != "" ]; then
    FRONTEND_ENI=$(aws ecs describe-tasks \
      --cluster todo-app-cluster \
      --tasks $FRONTEND_TASKS \
      --region us-east-1 \
      --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
      --output text)
    
    FRONTEND_IP=$(aws ec2 describe-network-interfaces \
      --network-interface-ids $FRONTEND_ENI \
      --region us-east-1 \
      --query 'NetworkInterfaces[0].Association.PublicIp' \
      --output text)
    
    echo "   IP: $FRONTEND_IP"
    echo "   URL: http://$FRONTEND_IP:3000"
else
    echo "   ❌ No running frontend tasks found"
fi

echo ""
echo "📝 For Cloudflare DNS setup, use these IPs:"
echo "================================================"
if [ "$FRONTEND_IP" != "None" ] && [ "$FRONTEND_IP" != "" ]; then
    echo "A record: @   → $FRONTEND_IP (proxied ✅)"
    echo "A record: www → $FRONTEND_IP (proxied ✅)"
fi

if [ "$BACKEND_IP" != "None" ] && [ "$BACKEND_IP" != "" ]; then
    echo "A record: api → $BACKEND_IP (proxied ✅)"
fi

echo ""
echo "🚀 Next steps:"
echo "1. Copy these IPs"
echo "2. Go to cloudflare.com and add your domain"
echo "3. Add the DNS records above"
echo "4. Update nameservers at your domain registrar"
echo "5. Enable SSL in Cloudflare dashboard"
echo ""
echo "📖 Full guide: SIMPLE-DOMAIN-SSL-SETUP.md" 