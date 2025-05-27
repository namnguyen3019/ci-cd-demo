#!/bin/bash

# AWS Application Load Balancer Setup Script
echo "🏗️ AWS Application Load Balancer Setup"
echo "======================================"

# Check if domain is provided
if [ -z "$1" ]; then
    echo "❌ Please provide your domain name"
    echo "Usage: ./create-alb.sh yourdomain.com"
    exit 1
fi

DOMAIN=$1
echo "🎯 Setting up ALB for domain: $DOMAIN"

# AWS Configuration
VPC_ID="vpc-0e2f1b8db99202357"
SUBNET1="subnet-073c62d41f5f2f178"
SUBNET2="subnet-0ffcb129c4743a018"
SECURITY_GROUP="sg-032def7bdaffd9850"
REGION="us-east-1"

echo "📋 Using AWS resources:"
echo "   VPC: $VPC_ID"
echo "   Subnets: $SUBNET1, $SUBNET2"
echo "   Security Group: $SECURITY_GROUP"
echo ""

# Step 1: Create Target Groups
echo "🎯 Step 1: Creating Target Groups..."

echo "   Creating frontend target group..."
FRONTEND_TG_ARN=$(aws elbv2 create-target-group \
  --name todo-frontend-tg \
  --protocol HTTP \
  --port 3000 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-enabled \
  --health-check-path / \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3 \
  --matcher HttpCode=200 \
  --region $REGION \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

echo "   ✅ Frontend TG: $FRONTEND_TG_ARN"

echo "   Creating backend target group..."
BACKEND_TG_ARN=$(aws elbv2 create-target-group \
  --name todo-backend-tg \
  --protocol HTTP \
  --port 8000 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-enabled \
  --health-check-path /api/todos/ \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3 \
  --matcher HttpCode=200 \
  --region $REGION \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

echo "   ✅ Backend TG: $BACKEND_TG_ARN"

# Step 2: Create Application Load Balancer
echo ""
echo "⚖️ Step 2: Creating Application Load Balancer..."

ALB_ARN=$(aws elbv2 create-load-balancer \
  --name todo-app-alb \
  --subnets $SUBNET1 $SUBNET2 \
  --security-groups $SECURITY_GROUP \
  --scheme internet-facing \
  --type application \
  --ip-address-type ipv4 \
  --tags Key=Name,Value=todo-app-alb Key=Environment,Value=production \
  --region $REGION \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

echo "   ✅ ALB ARN: $ALB_ARN"

# Get ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --region $REGION \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

echo "   ✅ ALB DNS: $ALB_DNS"

# Step 3: Request SSL Certificate
echo ""
echo "🔒 Step 3: Requesting SSL Certificate..."

CERTIFICATE_ARN=$(aws acm request-certificate \
  --domain-name $DOMAIN \
  --subject-alternative-names "*.$DOMAIN" \
  --validation-method DNS \
  --region $REGION \
  --tags Key=Name,Value=todo-app-cert \
  --query 'CertificateArn' \
  --output text)

echo "   ✅ Certificate ARN: $CERTIFICATE_ARN"

# Step 4: Create Route 53 Hosted Zone
echo ""
echo "🌐 Step 4: Creating Route 53 Hosted Zone..."

HOSTED_ZONE_ID=$(aws route53 create-hosted-zone \
  --name $DOMAIN \
  --caller-reference $(date +%s) \
  --hosted-zone-config Comment="Todo App Domain" \
  --query 'HostedZone.Id' \
  --output text | sed 's|/hostedzone/||')

echo "   ✅ Hosted Zone ID: $HOSTED_ZONE_ID"

# Get nameservers
echo "   📋 Nameservers for your domain registrar:"
aws route53 get-hosted-zone \
  --id $HOSTED_ZONE_ID \
  --query 'DelegationSet.NameServers' \
  --output table

# Step 5: Create HTTP Listener (redirect to HTTPS)
echo ""
echo "🔗 Step 5: Creating HTTP Listener (redirects to HTTPS)..."

HTTP_LISTENER_ARN=$(aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=redirect,RedirectConfig='{Protocol=HTTPS,Port=443,StatusCode=HTTP_301}' \
  --region $REGION \
  --query 'Listeners[0].ListenerArn' \
  --output text)

echo "   ✅ HTTP Listener: $HTTP_LISTENER_ARN"

# Step 6: Wait for certificate validation
echo ""
echo "⏳ Step 6: Waiting for SSL certificate validation..."
echo "   📋 You need to validate the certificate in AWS Console or add DNS records manually"
echo "   🔗 Go to: https://console.aws.amazon.com/acm/home?region=us-east-1#/certificates"
echo ""
echo "   Or get validation records with:"
echo "   aws acm describe-certificate --certificate-arn $CERTIFICATE_ARN --region $REGION"
echo ""

read -p "Press Enter when certificate is validated and shows 'Issued' status..."

# Step 7: Create HTTPS Listener
echo ""
echo "🔒 Step 7: Creating HTTPS Listener..."

HTTPS_LISTENER_ARN=$(aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=$CERTIFICATE_ARN \
  --default-actions Type=forward,TargetGroupArn=$FRONTEND_TG_ARN \
  --region $REGION \
  --query 'Listeners[0].ListenerArn' \
  --output text)

echo "   ✅ HTTPS Listener: $HTTPS_LISTENER_ARN"

# Step 8: Create API routing rule
echo ""
echo "🔀 Step 8: Creating API routing rule..."

aws elbv2 create-rule \
  --listener-arn $HTTPS_LISTENER_ARN \
  --priority 100 \
  --conditions Field=path-pattern,Values="/api/*" \
  --actions Type=forward,TargetGroupArn=$BACKEND_TG_ARN \
  --region $REGION

echo "   ✅ API routing rule created"

# Step 9: Create Route 53 A record
echo ""
echo "📍 Step 9: Creating Route 53 A record..."

# Get ALB hosted zone ID (for us-east-1)
ALB_ZONE_ID="Z35SXDOTRQ7X7K"

aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "'$DOMAIN'",
        "Type": "A",
        "AliasTarget": {
          "DNSName": "'$ALB_DNS'",
          "EvaluateTargetHealth": false,
          "HostedZoneId": "'$ALB_ZONE_ID'"
        }
      }
    }]
  }'

echo "   ✅ A record created for $DOMAIN"

# Step 10: Update application configuration
echo ""
echo "🔧 Step 10: Updating application configuration..."

# Update frontend environment
echo "NEXT_PUBLIC_API_URL=https://$DOMAIN/api" > frontend/.env.production
echo "   ✅ Updated frontend to use: https://$DOMAIN/api"

# Update Django settings
cat >> backend/todoproject/settings.py << EOF

# ALB Configuration
ALLOWED_HOSTS = [
    '$DOMAIN',
    'www.$DOMAIN',
]

CORS_ALLOWED_ORIGINS = [
    "https://$DOMAIN",
    "https://www.$DOMAIN",
    "http://localhost:3000",  # Keep for local development
]

# ALB handles SSL termination
SECURE_SSL_REDIRECT = False
USE_TZ = True
EOF

echo "   ✅ Updated Django CORS and ALLOWED_HOSTS"

# Save configuration
echo ""
echo "💾 Saving configuration..."

cat > alb-config.txt << EOF
# ALB Configuration for $DOMAIN
ALB_ARN=$ALB_ARN
ALB_DNS=$ALB_DNS
FRONTEND_TG_ARN=$FRONTEND_TG_ARN
BACKEND_TG_ARN=$BACKEND_TG_ARN
CERTIFICATE_ARN=$CERTIFICATE_ARN
HOSTED_ZONE_ID=$HOSTED_ZONE_ID
HTTPS_LISTENER_ARN=$HTTPS_LISTENER_ARN
HTTP_LISTENER_ARN=$HTTP_LISTENER_ARN
EOF

echo "   ✅ Configuration saved to alb-config.txt"

# Commit changes
echo ""
echo "📦 Committing changes..."
git add .
git commit -m "Configure ALB for domain: $DOMAIN"

echo ""
echo "🎊 ALB Setup Complete!"
echo "===================="
echo ""
echo "📋 Summary:"
echo "   🌐 Domain: $DOMAIN"
echo "   ⚖️ Load Balancer: $ALB_DNS"
echo "   🔒 SSL Certificate: Configured"
echo "   📍 Route 53: Configured"
echo ""
echo "🚀 Next Steps:"
echo "1. Update nameservers at your domain registrar with the ones shown above"
echo "2. Wait 5-10 minutes for DNS propagation"
echo "3. Update ECS services to use target groups:"
echo "   ./update-ecs-for-alb.sh"
echo "4. Push changes to trigger deployment:"
echo "   git push origin main"
echo ""
echo "🎯 Your sites will be available at:"
echo "   🎨 Frontend: https://$DOMAIN"
echo "   🔧 API: https://$DOMAIN/api/todos/"
echo ""
echo "📊 Monitor your ALB:"
echo "   🔗 https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#LoadBalancers:"
echo ""
echo "📖 Full guide: AWS-ALB-DETAILED-GUIDE.md" 