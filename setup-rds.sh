#!/bin/bash

# RDS Setup Script for Todo App
# This script uses the actual subnet and security group IDs from your AWS environment

set -e  # Exit on any error

echo "🚀 Setting up RDS PostgreSQL for Todo App..."
echo "=============================================="

# Configuration
DB_PASSWORD="TodoApp2024!SecurePass"  # Change this to your preferred password
REGION="us-east-1"
VPC_ID="vpc-0e2f1b8db99202357"
SUBNET_IDS="subnet-073c62d41f5f2f178 subnet-0ffcb129c4743a018"
SECURITY_GROUP_ID="sg-032def7bdaffd9850"

echo "📋 Configuration:"
echo "  - Region: $REGION"
echo "  - VPC: $VPC_ID"
echo "  - Subnets: $SUBNET_IDS"
echo "  - Security Group: $SECURITY_GROUP_ID"
echo ""

# Step 1: Create DB Subnet Group
echo "1️⃣ Creating DB subnet group..."
aws rds create-db-subnet-group \
    --db-subnet-group-name todo-db-subnet-group \
    --db-subnet-group-description "Subnet group for Todo app database" \
    --subnet-ids $SUBNET_IDS \
    --region $REGION

if [ $? -eq 0 ]; then
    echo "✅ DB subnet group created successfully"
else
    echo "❌ Failed to create DB subnet group"
    exit 1
fi

echo ""

# Step 2: Create RDS Instance
echo "2️⃣ Creating RDS PostgreSQL instance..."
echo "⏳ This will take 5-10 minutes..."

aws rds create-db-instance \
    --db-instance-identifier todo-app-db \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --master-username todouser \
    --master-user-password "$DB_PASSWORD" \
    --allocated-storage 20 \
    --db-name todoapp \
    --vpc-security-group-ids $SECURITY_GROUP_ID \
    --db-subnet-group-name todo-db-subnet-group \
    --backup-retention-period 7 \
    --storage-encrypted \
    --region $REGION

if [ $? -eq 0 ]; then
    echo "✅ RDS instance creation initiated"
else
    echo "❌ Failed to create RDS instance"
    exit 1
fi

echo ""
echo "⏳ Waiting for RDS instance to become available..."

# Wait for RDS to be available
while true; do
    STATUS=$(aws rds describe-db-instances --db-instance-identifier todo-app-db --region $REGION --query 'DBInstances[0].DBInstanceStatus' --output text 2>/dev/null || echo "creating")
    
    if [ "$STATUS" = "available" ]; then
        echo "✅ RDS instance is now available!"
        break
    elif [ "$STATUS" = "failed" ]; then
        echo "❌ RDS instance creation failed"
        exit 1
    else
        echo "   Status: $STATUS (waiting...)"
        sleep 30
    fi
done

# Get RDS endpoint
echo ""
echo "3️⃣ Getting RDS endpoint..."
RDS_ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier todo-app-db --region $REGION --query 'DBInstances[0].Endpoint.Address' --output text)

echo ""
echo "🎉 RDS Setup Complete!"
echo "======================"
echo "📝 Important Information:"
echo "  - RDS Endpoint: $RDS_ENDPOINT"
echo "  - Database Name: todoapp"
echo "  - Username: todouser"
echo "  - Password: $DB_PASSWORD"
echo ""
echo "🔧 Next Steps:"
echo "1. Update your task definitions (.aws/task-definition-*.json) with:"
echo "   - Replace 'YOUR_RDS_ENDPOINT' with: $RDS_ENDPOINT"
echo "   - Replace 'YOUR_ACCOUNT_ID' with your AWS account ID"
echo ""
echo "2. Create secrets in AWS Secrets Manager:"
echo "   aws secretsmanager create-secret --name 'todo-app/django-secret-key' --secret-string 'your-super-secret-django-key' --region $REGION"
echo "   aws secretsmanager create-secret --name 'todo-app/db-credentials' --secret-string '{\"username\":\"todouser\",\"password\":\"$DB_PASSWORD\"}' --region $REGION"
echo ""
echo "3. Configure security group to allow ECS access (port 5432)"

# Save configuration to file
cat > rds-config.txt << EOF
RDS Configuration for Todo App
==============================
RDS Endpoint: $RDS_ENDPOINT
Database Name: todoapp
Username: todouser
Password: $DB_PASSWORD
Region: $REGION
VPC ID: $VPC_ID
Security Group: $SECURITY_GROUP_ID
Subnets: $SUBNET_IDS

Created: $(date)
EOF

echo ""
echo "💾 Configuration saved to: rds-config.txt" 