#!/bin/bash

# Set variables
REGION="us-east-1"

echo "Registering task definitions..."

# Register backend task definition
echo "Registering backend task definition..."
aws ecs register-task-definition \
    --cli-input-json file://.aws/task-definition-backend.json \
    --region $REGION

if [ $? -eq 0 ]; then
    echo "✅ Backend task definition registered successfully"
else
    echo "❌ Failed to register backend task definition"
fi

# Register frontend task definition
echo "Registering frontend task definition..."
aws ecs register-task-definition \
    --cli-input-json file://.aws/task-definition-frontend.json \
    --region $REGION

if [ $? -eq 0 ]; then
    echo "✅ Frontend task definition registered successfully"
else
    echo "❌ Failed to register frontend task definition"
fi

echo "Task definition registration completed!" 