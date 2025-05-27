# 🌐 How to Access Your Todo Website

## 🔍 **Current Status Check**

Your CI/CD pipeline is either still running or needs to be triggered. Here's how to check and access your website:

## 1️⃣ **Check GitHub Actions Status**

First, check if your CI/CD pipeline is running:

```bash
# Open GitHub Actions in browser
open https://github.com/namnguyen3019/ci-cd-demo/actions

# Or check via CLI
gh run list --limit 5
```

**Expected Status:**
- ✅ **Running**: Pipeline is currently deploying
- ✅ **Completed**: Deployment finished successfully  
- ❌ **Failed**: Check logs for errors

## 2️⃣ **Check ECS Services Status**

Once the pipeline completes, check if your services are running:

```bash
# Check if services exist and are running
aws ecs describe-services \
  --cluster todo-app-cluster \
  --services todo-backend-service todo-frontend-service \
  --region us-east-1 \
  --query 'services[*].[serviceName,status,runningCount,pendingCount]' \
  --output table
```

## 3️⃣ **Get Public IP Addresses**

Once services are running, get their public IPs:

```bash
# Get running tasks
aws ecs list-tasks --cluster todo-app-cluster --region us-east-1

# Get task details (replace TASK_ARN with actual ARN from above)
aws ecs describe-tasks \
  --cluster todo-app-cluster \
  --tasks TASK_ARN \
  --region us-east-1 \
  --query 'tasks[*].attachments[0].details[?name==`networkInterfaceId`].value' \
  --output text

# Get public IP from network interface (replace ENI_ID with actual ID)
aws ec2 describe-network-interfaces \
  --network-interface-ids ENI_ID \
  --region us-east-1 \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text
```

## 4️⃣ **Access Your Website**

### **Frontend (Next.js Todo App)**
```
http://FRONTEND_PUBLIC_IP:3000
```

### **Backend API (Django REST API)**
```
http://BACKEND_PUBLIC_IP:8000/api/todos/
```

## 🚀 **Quick Access Script**

Let me create a script to automatically find and display your website URLs:

```bash
# Run this script to get your website URLs
./get-website-urls.sh
```

## 🔧 **If Services Aren't Running Yet**

### **Option A: Wait for Automatic Deployment**
The CI/CD pipeline should trigger automatically. Check GitHub Actions.

### **Option B: Trigger Deployment Manually**
```bash
# Make a small change and push to trigger deployment
echo "# Todo App - $(date)" >> README.md
git add README.md
git commit -m "Trigger deployment"
git push origin main
```

### **Option C: Create Services Manually (if pipeline fails)**
```bash
# Register task definitions
aws ecs register-task-definition --cli-input-json file://.aws/task-definition-backend.json
aws ecs register-task-definition --cli-input-json file://.aws/task-definition-frontend.json

# Create services
aws ecs create-service \
  --cluster todo-app-cluster \
  --service-name todo-backend-service \
  --task-definition todo-backend-task \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-073c62d41f5f2f178,subnet-0ffcb129c4743a018],securityGroups=[sg-032def7bdaffd9850],assignPublicIp=ENABLED}"

aws ecs create-service \
  --cluster todo-app-cluster \
  --service-name todo-frontend-service \
  --task-definition todo-frontend-task \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-073c62d41f5f2f178,subnet-0ffcb129c4743a018],securityGroups=[sg-032def7bdaffd9850],assignPublicIp=ENABLED}"
```

## 📊 **Monitoring Links**

- **GitHub Actions**: https://github.com/namnguyen3019/ci-cd-demo/actions
- **AWS ECS Console**: https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/todo-app-cluster
- **CloudWatch Logs**: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups

## 🎯 **Expected Timeline**

- **First Deployment**: 15-25 minutes
- **Subsequent Deployments**: 10-15 minutes

## 🔍 **Troubleshooting**

### **If GitHub Actions Failed:**
1. Check the workflow logs for specific errors
2. Verify AWS credentials are correct
3. Ensure all AWS resources exist

### **If Services Won't Start:**
1. Check CloudWatch logs for container errors
2. Verify task definitions are correct
3. Check security group rules
4. Ensure RDS database is accessible

### **If Website Doesn't Load:**
1. Verify public IP is accessible
2. Check security group allows HTTP/HTTPS traffic
3. Ensure containers are healthy
4. Check application logs

## 🎊 **Success Indicators**

Your website is ready when:
- ✅ GitHub Actions shows green checkmarks
- ✅ ECS services show "RUNNING" status
- ✅ Tasks are healthy
- ✅ Website responds at public IP addresses

## 🔮 **Future Enhancement: Load Balancer**

For production use, consider adding an Application Load Balancer:
- Provides a stable domain name
- Handles SSL/TLS certificates
- Distributes traffic across multiple tasks
- Enables auto-scaling

Would you like me to help set up a load balancer for easier access? 