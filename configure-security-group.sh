#!/bin/bash

# Configure Security Group for Database Access
# This script adds the necessary inbound rule to allow ECS tasks to access PostgreSQL

set -e

echo "🔒 Configuring Security Group for Database Access..."
echo "=================================================="

# Configuration
SECURITY_GROUP_ID="sg-032def7bdaffd9850"
REGION="us-east-1"

echo "📋 Configuration:"
echo "  - Security Group: $SECURITY_GROUP_ID"
echo "  - Region: $REGION"
echo ""

echo "1️⃣ Checking current security group rules..."

# Show current inbound rules
echo "Current inbound rules:"
aws ec2 describe-security-groups \
    --group-ids $SECURITY_GROUP_ID \
    --region $REGION \
    --query 'SecurityGroups[0].IpPermissions[*].[IpProtocol,FromPort,ToPort,IpRanges[0].CidrIp,UserIdGroupPairs[0].GroupId]' \
    --output table 2>/dev/null || echo "No existing rules or error retrieving rules"

echo ""
echo "2️⃣ Adding PostgreSQL access rule..."

# Add inbound rule for PostgreSQL (port 5432) from the same security group
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 5432 \
    --source-group $SECURITY_GROUP_ID \
    --region $REGION 2>/dev/null && echo "✅ PostgreSQL rule added successfully" || echo "⚠️  Rule may already exist"

echo ""
echo "3️⃣ Adding HTTP access rule for ECS tasks..."

# Add inbound rule for HTTP (port 80) from anywhere (for ALB to reach ECS)
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --region $REGION 2>/dev/null && echo "✅ HTTP rule added successfully" || echo "⚠️  Rule may already exist"

echo ""
echo "4️⃣ Adding HTTPS access rule for ECS tasks..."

# Add inbound rule for HTTPS (port 443) from anywhere (for ALB to reach ECS)
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0 \
    --region $REGION 2>/dev/null && echo "✅ HTTPS rule added successfully" || echo "⚠️  Rule may already exist"

echo ""
echo "5️⃣ Adding application ports for ECS services..."

# Add inbound rule for backend service (port 8000)
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 8000 \
    --source-group $SECURITY_GROUP_ID \
    --region $REGION 2>/dev/null && echo "✅ Backend port (8000) rule added successfully" || echo "⚠️  Rule may already exist"

# Add inbound rule for frontend service (port 3000)
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 3000 \
    --source-group $SECURITY_GROUP_ID \
    --region $REGION 2>/dev/null && echo "✅ Frontend port (3000) rule added successfully" || echo "⚠️  Rule may already exist"

echo ""
echo "6️⃣ Verifying updated security group rules..."

# Show updated inbound rules
echo "Updated inbound rules:"
aws ec2 describe-security-groups \
    --group-ids $SECURITY_GROUP_ID \
    --region $REGION \
    --query 'SecurityGroups[0].IpPermissions[*].[IpProtocol,FromPort,ToPort,IpRanges[0].CidrIp,UserIdGroupPairs[0].GroupId]' \
    --output table

echo ""
echo "🎉 Security Group Configuration Complete!"
echo "========================================"
echo "📝 Added Rules:"
echo "  ✅ PostgreSQL (5432) - Self-referencing for database access"
echo "  ✅ HTTP (80) - Public access for load balancer"
echo "  ✅ HTTPS (443) - Public access for load balancer"
echo "  ✅ Backend (8000) - Self-referencing for service communication"
echo "  ✅ Frontend (3000) - Self-referencing for service communication"
echo ""
echo "🔧 Next Steps:"
echo "1. Set up GitHub repository secrets"
echo "2. Create ECS services (or let CI/CD create them)"
echo "3. Test the deployment pipeline"
echo ""
echo "💡 Note: Self-referencing rules allow resources within the same security group to communicate with each other." 