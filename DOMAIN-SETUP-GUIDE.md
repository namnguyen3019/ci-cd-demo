# 🌐 Domain Setup Guide for Todo App

## 🎯 **Overview**

This guide will help you set up a custom domain for your Todo app. We'll cover multiple approaches from simple to production-ready.

## 📋 **Prerequisites**

1. **Domain Name**: You need to own a domain (e.g., `yourdomain.com`)
2. **Domain Registrar Access**: Access to your domain's DNS settings
3. **AWS Account**: Your existing AWS setup
4. **Running Application**: Your Todo app should be deployed and accessible via IP

## 🚀 **Option 1: Simple DNS Pointing (Quick Setup)**

### **Step 1: Get Your Application IPs**

First, let's get your current public IPs:

```bash
# Run the script to get your current IPs
./get-website-urls.sh
```

### **Step 2: Configure DNS Records**

In your domain registrar's DNS settings, add these A records:

```
# Frontend
todo.yourdomain.com    →    FRONTEND_PUBLIC_IP
api.yourdomain.com     →    BACKEND_PUBLIC_IP

# Or use subdomains
app.yourdomain.com     →    FRONTEND_PUBLIC_IP
api.yourdomain.com     →    BACKEND_PUBLIC_IP
```

### **Step 3: Update Frontend Configuration**

Update your frontend to use the API domain:

```bash
# Update frontend environment variables
echo "NEXT_PUBLIC_API_URL=http://api.yourdomain.com:8000" >> frontend/.env.production
```

### **⚠️ Limitations of This Approach:**
- No SSL/HTTPS (browsers may block)
- IP addresses can change when ECS tasks restart
- Not suitable for production

---

## 🏗️ **Option 2: AWS Application Load Balancer (Recommended)**

This is the production-ready approach with SSL certificates and stable endpoints.

### **Step 1: Create Load Balancer Infrastructure**

I'll create Terraform configuration for this:

```bash
# Add load balancer to your infrastructure
cd terraform-example
terraform plan
terraform apply
```

### **Step 2: Configure Route 53 (AWS DNS)**

```bash
# Create hosted zone for your domain
aws route53 create-hosted-zone \
  --name yourdomain.com \
  --caller-reference $(date +%s)
```

### **Step 3: SSL Certificate**

```bash
# Request SSL certificate
aws acm request-certificate \
  --domain-name yourdomain.com \
  --subject-alternative-names "*.yourdomain.com" \
  --validation-method DNS \
  --region us-east-1
```

---

## 🔧 **Option 3: Cloudflare (Easy + Free SSL)**

### **Step 1: Add Domain to Cloudflare**

1. Sign up at [Cloudflare](https://cloudflare.com)
2. Add your domain
3. Update nameservers at your registrar

### **Step 2: Configure DNS in Cloudflare**

```
Type: A
Name: todo
Content: FRONTEND_PUBLIC_IP
Proxy: ✅ (Orange cloud)

Type: A  
Name: api
Content: BACKEND_PUBLIC_IP
Proxy: ✅ (Orange cloud)
```

### **Step 3: Configure SSL**

In Cloudflare dashboard:
- SSL/TLS → Overview → Full (strict)
- Edge Certificates → Always Use HTTPS: On

---

## 🎯 **Recommended Production Setup**

Let me create the complete infrastructure for a production domain setup:

### **What We'll Create:**
- Application Load Balancer
- Route 53 hosted zone
- SSL certificate
- Target groups for frontend/backend
- Updated ECS services

### **Benefits:**
- ✅ Stable domain names
- ✅ SSL/HTTPS encryption
- ✅ Auto-scaling support
- ✅ Health checks
- ✅ Professional setup

---

## 🚀 **Quick Start: Choose Your Path**

### **For Testing/Development:**
```bash
# Option 1: Simple DNS pointing
# Just update your DNS records manually
```

### **For Production:**
```bash
# Option 2: Full AWS setup with Load Balancer
cd terraform-example
terraform apply
```

### **For Easy Setup with Free SSL:**
```bash
# Option 3: Cloudflare
# Sign up and configure DNS
```

---

## 📝 **Next Steps**

1. **Choose your approach** based on your needs
2. **Get your domain ready** (purchase if needed)
3. **Follow the specific setup** for your chosen option
4. **Test the configuration**
5. **Update application URLs**

---

## 🔍 **Domain Providers Recommendations**

### **Budget-Friendly:**
- Namecheap
- Google Domains
- Cloudflare Registrar

### **Enterprise:**
- AWS Route 53
- GoDaddy Pro

---

## 🛠️ **Troubleshooting**

### **DNS Not Resolving:**
```bash
# Check DNS propagation
nslookup yourdomain.com
dig yourdomain.com

# Online tools
# https://dnschecker.org
```

### **SSL Certificate Issues:**
```bash
# Check certificate status
aws acm list-certificates --region us-east-1
```

### **Load Balancer Health Checks:**
```bash
# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn TARGET_GROUP_ARN
```

---

## 🎊 **Success Checklist**

- [ ] Domain purchased and accessible
- [ ] DNS records configured
- [ ] SSL certificate issued (if using HTTPS)
- [ ] Load balancer created (if using Option 2)
- [ ] Application accessible via domain
- [ ] HTTPS working (if configured)
- [ ] API endpoints working with new domain

---

**Which option would you like to implement? I can help you set up any of these approaches!** 