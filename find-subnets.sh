#!/bin/bash

echo "🔍 Finding available subnets for RDS setup..."
echo "================================================"

# Get default VPC ID
DEFAULT_VPC=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region us-east-1)

if [ "$DEFAULT_VPC" = "None" ] || [ -z "$DEFAULT_VPC" ]; then
    echo "❌ No default VPC found. Let's check all VPCs:"
    aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,State,IsDefault,CidrBlock]' --output table --region us-east-1
    echo ""
    echo "Please choose a VPC ID and run:"
    echo "aws ec2 describe-subnets --filters \"Name=vpc-id,Values=YOUR_VPC_ID\" --query 'Subnets[*].[SubnetId,AvailabilityZone,State,CidrBlock]' --output table --region us-east-1"
else
    echo "✅ Default VPC found: $DEFAULT_VPC"
    echo ""
    echo "📋 Available subnets in default VPC:"
    aws ec2 describe-subnets --filters "Name=vpc-id,Values=$DEFAULT_VPC" --query 'Subnets[*].[SubnetId,AvailabilityZone,State,CidrBlock]' --output table --region us-east-1
    
    echo ""
    echo "🎯 Recommended subnets for RDS (need at least 2 in different AZs):"
    SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$DEFAULT_VPC" --query 'Subnets[?State==`available`].[SubnetId,AvailabilityZone]' --output text --region us-east-1)
    
    echo "$SUBNETS" | head -2 | while read subnet_id az; do
        echo "  - Subnet: $subnet_id (AZ: $az)"
    done
    
    echo ""
    echo "📝 Copy these subnet IDs for your RDS command:"
    SUBNET_LIST=$(echo "$SUBNETS" | head -2 | awk '{print $1}' | tr '\n' ' ')
    echo "   $SUBNET_LIST"
fi

echo ""
echo "🔧 Next steps:"
echo "1. Copy the subnet IDs from above"
echo "2. Replace 'subnet-12345678 subnet-87654321' in the RDS command with your actual subnet IDs"
echo "3. Make sure you have at least 2 subnets in different availability zones" 