# 🏗️ AWS Application Load Balancer - Complete Guide

## 🎯 **What is AWS Application Load Balancer (ALB)?**

An Application Load Balancer is AWS's Layer 7 load balancer that distributes incoming traffic across multiple targets (like your ECS tasks) and provides advanced routing, SSL termination, and health checks.

## 🚀 **Why Choose ALB over Cloudflare?**

### **ALB Advantages:**
- ✅ **Native AWS Integration** - Works seamlessly with ECS, Route 53, ACM
- ✅ **Advanced Health Checks** - Automatic failover if containers fail
- ✅ **Path-Based Routing** - Route `/api/*` to backend, everything else to frontend
- ✅ **Auto Scaling Support** - Works with ECS auto-scaling
- ✅ **AWS WAF Integration** - Advanced security features
- ✅ **Sticky Sessions** - If you need session persistence
- ✅ **WebSocket Support** - For real-time features
- ✅ **Better Monitoring** - CloudWatch metrics and logs

### **When to Choose ALB:**
- 🎯 **Production AWS-heavy applications**
- 🎯 **Need advanced routing** (different paths to different services)
- 🎯 **Want auto-scaling capabilities**
- 🎯 **Need detailed AWS monitoring**
- 🎯 **Planning to add more microservices**
- 🎯 **Want everything in AWS ecosystem**

## 💰 **Cost Breakdown**

### **ALB Costs:**
- **Load Balancer**: ~$16/month (always running)
- **LCU (Load Balancer Capacity Units)**: ~$5-10/month (based on traffic)
- **Total**: ~$20-25/month

### **Additional AWS Costs:**
- **Route 53 Hosted Zone**: $0.50/month
- **SSL Certificate (ACM)**: FREE
- **Data Transfer**: Varies by usage

### **vs Cloudflare:**
- **Cloudflare**: FREE (with some limitations)
- **ALB**: $20-25/month (but more features)

## 🏗️ **Complete ALB Setup Process**

### **Architecture Overview:**
```
Internet → Route 53 → ALB → Target Groups → ECS Tasks
                      ↓
                   SSL Certificate (ACM)
```

### **Step 1: Create Target Groups**

Target groups define where ALB sends traffic:

```bash
# Frontend target group (for your Next.js app)
aws elbv2 create-target-group \
  --name todo-frontend-tg \
  --protocol HTTP \
  --port 3000 \
  --vpc-id vpc-0e2f1b8db99202357 \
  --target-type ip \
  --health-check-enabled \
  --health-check-path / \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3 \
  --matcher HttpCode=200

# Backend target group (for your Django API)
aws elbv2 create-target-group \
  --name todo-backend-tg \
  --protocol HTTP \
  --port 8000 \
  --vpc-id vpc-0e2f1b8db99202357 \
  --target-type ip \
  --health-check-enabled \
  --health-check-path /api/todos/ \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3 \
  --matcher HttpCode=200
```

### **Step 2: Create Application Load Balancer**

```bash
# Create the ALB
aws elbv2 create-load-balancer \
  --name todo-app-alb \
  --subnets subnet-073c62d41f5f2f178 subnet-0ffcb129c4743a018 \
  --security-groups sg-032def7bdaffd9850 \
  --scheme internet-facing \
  --type application \
  --ip-address-type ipv4 \
  --tags Key=Name,Value=todo-app-alb Key=Environment,Value=production
```

### **Step 3: Request SSL Certificate**

```bash
# Request SSL certificate for your domain
aws acm request-certificate \
  --domain-name yourdomain.com \
  --subject-alternative-names "*.yourdomain.com" \
  --validation-method DNS \
  --region us-east-1 \
  --tags Key=Name,Value=todo-app-cert

# Get certificate ARN (save this!)
aws acm list-certificates --region us-east-1
```

### **Step 4: Create Route 53 Hosted Zone**

```bash
# Create hosted zone for your domain
aws route53 create-hosted-zone \
  --name yourdomain.com \
  --caller-reference $(date +%s) \
  --hosted-zone-config Comment="Todo App Domain"
```

### **Step 5: Validate SSL Certificate**

After requesting the certificate, you need to validate it:

```bash
# Get validation records
aws acm describe-certificate \
  --certificate-arn YOUR_CERTIFICATE_ARN \
  --region us-east-1

# Add the CNAME records to Route 53 for validation
# (AWS Console makes this easier with one-click validation)
```

### **Step 6: Create ALB Listeners**

Once certificate is validated:

```bash
# Get ARNs from previous steps
ALB_ARN="arn:aws:elasticloadbalancing:us-east-1:533218240958:loadbalancer/app/todo-app-alb/..."
FRONTEND_TG_ARN="arn:aws:elasticloadbalancing:us-east-1:533218240958:targetgroup/todo-frontend-tg/..."
BACKEND_TG_ARN="arn:aws:elasticloadbalancing:us-east-1:533218240958:targetgroup/todo-backend-tg/..."
CERTIFICATE_ARN="arn:aws:acm:us-east-1:533218240958:certificate/..."

# HTTPS Listener with path-based routing
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=$CERTIFICATE_ARN \
  --default-actions Type=forward,TargetGroupArn=$FRONTEND_TG_ARN

# Add rule for API traffic
aws elbv2 create-rule \
  --listener-arn LISTENER_ARN_FROM_ABOVE \
  --priority 100 \
  --conditions Field=path-pattern,Values="/api/*" \
  --actions Type=forward,TargetGroupArn=$BACKEND_TG_ARN

# HTTP Listener (redirects to HTTPS)
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=redirect,RedirectConfig='{Protocol=HTTPS,Port=443,StatusCode=HTTP_301}'
```

### **Step 7: Update ECS Services**

Modify your ECS services to register with target groups:

```bash
# Update backend service
aws ecs update-service \
  --cluster todo-app-cluster \
  --service todo-backend-service \
  --load-balancers targetGroupArn=$BACKEND_TG_ARN,containerName=todo-backend,containerPort=8000

# Update frontend service  
aws ecs update-service \
  --cluster todo-app-cluster \
  --service todo-frontend-service \
  --load-balancers targetGroupArn=$FRONTEND_TG_ARN,containerName=todo-frontend,containerPort=3000
```

### **Step 8: Create Route 53 Records**

```bash
# Get ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

# Create A record pointing to ALB
aws route53 change-resource-record-sets \
  --hosted-zone-id YOUR_HOSTED_ZONE_ID \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "yourdomain.com",
        "Type": "A",
        "AliasTarget": {
          "DNSName": "'$ALB_DNS'",
          "EvaluateTargetHealth": false,
          "HostedZoneId": "Z35SXDOTRQ7X7K"
        }
      }
    }]
  }'
```

## 🎯 **Advanced ALB Features**

### **Path-Based Routing:**
```
yourdomain.com/          → Frontend (Next.js)
yourdomain.com/api/*     → Backend (Django)
yourdomain.com/admin/*   → Backend (Django Admin)
```

### **Health Checks:**
- ALB automatically removes unhealthy targets
- Configurable health check paths
- Automatic failover

### **Auto Scaling Integration:**
```bash
# ECS will automatically register new tasks with ALB
# when scaling up/down
```

### **Monitoring:**
- CloudWatch metrics (request count, latency, errors)
- Access logs to S3
- Integration with AWS X-Ray for tracing

## 🔧 **Configuration for Your Todo App**

### **Update Frontend Environment:**
```bash
# No port needed with ALB!
echo "NEXT_PUBLIC_API_URL=https://yourdomain.com/api" > frontend/.env.production
```

### **Update Django Settings:**
```python
# backend/todoproject/settings.py
ALLOWED_HOSTS = [
    'yourdomain.com',
    'www.yourdomain.com',
]

CORS_ALLOWED_ORIGINS = [
    "https://yourdomain.com",
    "https://www.yourdomain.com",
]

# For ALB health checks
SECURE_SSL_REDIRECT = False  # ALB handles SSL termination
```

## 📊 **ALB vs Cloudflare Comparison**

| Feature | ALB | Cloudflare |
|---------|-----|------------|
| **Setup Complexity** | High | Low |
| **Cost** | $20-25/month | Free |
| **SSL** | Free (ACM) | Free |
| **Health Checks** | Advanced | Basic |
| **Auto Scaling** | Native | Manual |
| **Path Routing** | Advanced | Basic |
| **AWS Integration** | Perfect | External |
| **Global CDN** | No | Yes |
| **DDoS Protection** | Basic | Advanced |

## 🚀 **Quick Setup Script**

Let me create a script to automate the ALB setup:

```bash
# Coming up: create-alb.sh script
```

## 🎯 **When to Choose ALB:**

### **Choose ALB if:**
- ✅ You're building a serious production application
- ✅ You plan to scale beyond 2-3 services
- ✅ You need advanced health checks
- ✅ You want everything in AWS
- ✅ Budget allows $20-25/month
- ✅ You need path-based routing

### **Choose Cloudflare if:**
- ✅ You want quick setup (15 minutes)
- ✅ Budget is tight (free)
- ✅ You want global CDN
- ✅ Simple application
- ✅ Don't need advanced AWS features

## 🔍 **Troubleshooting ALB**

### **Common Issues:**
1. **Health checks failing** - Check security groups and health check paths
2. **SSL certificate not validating** - Verify DNS records
3. **502 errors** - Check target group health
4. **Route 53 not resolving** - Check nameservers

### **Monitoring Commands:**
```bash
# Check target health
aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN

# Check ALB status
aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN

# View CloudWatch metrics
aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB
```

## 🎊 **Final Result with ALB:**

- ✅ `https://yourdomain.com` - Your Todo app
- ✅ `https://yourdomain.com/api/todos/` - Your API (same domain!)
- ✅ Advanced health checks and monitoring
- ✅ Auto-scaling ready
- ✅ Professional AWS setup
- ✅ Path-based routing

**Would you like me to create the automated setup script for ALB?** 