# 🌐 Simple Domain + SSL Setup (No Terraform)

## 🎯 **Two Best Options for Domain + SSL**

### **Option A: Cloudflare (Easiest + Free SSL)**
### **Option B: AWS Application Load Balancer (More Control)**

---

## 🚀 **Option A: Cloudflare Setup (Recommended for Simplicity)**

### **Why Cloudflare?**
- ✅ **Free SSL certificates**
- ✅ **Easy setup** (15 minutes)
- ✅ **Global CDN** (faster loading)
- ✅ **DDoS protection**
- ✅ **Works with any domain registrar**

### **Step 1: Get Your Current IPs**

First, let's get your application's public IPs:

```bash
# Run this to get your current IPs
./get-website-urls.sh
```

You'll get something like:
```
Frontend: http://54.123.45.67:3000
Backend:  http://54.123.45.89:8000
```

### **Step 2: Sign Up for Cloudflare**

1. Go to [cloudflare.com](https://cloudflare.com)
2. Sign up for free account
3. Click "Add a Site"
4. Enter your domain name (e.g., `yourdomain.com`)

### **Step 3: Configure DNS Records**

In Cloudflare dashboard, add these DNS records:

```
Type: A
Name: @
Content: 54.123.45.67  (your frontend IP)
Proxy: ✅ (Orange cloud - this enables SSL)

Type: A
Name: api
Content: 54.123.45.89  (your backend IP)  
Proxy: ✅ (Orange cloud - this enables SSL)

Type: CNAME
Name: www
Content: yourdomain.com
Proxy: ✅ (Orange cloud)
```

### **Step 4: Update Nameservers**

Cloudflare will give you nameservers like:
```
ns1.cloudflare.com
ns2.cloudflare.com
```

Go to your domain registrar and update nameservers to these.

### **Step 5: Configure SSL**

In Cloudflare dashboard:
1. Go to **SSL/TLS** → **Overview**
2. Set to **"Full (strict)"**
3. Go to **SSL/TLS** → **Edge Certificates**
4. Turn on **"Always Use HTTPS"**

### **Step 6: Update Your Application**

Update your frontend to use the new API URL:

```bash
# Update frontend environment variable
echo "NEXT_PUBLIC_API_URL=https://api.yourdomain.com" > frontend/.env.production
```

### **Step 7: Rebuild and Deploy**

```bash
# Trigger a new deployment
git add .
git commit -m "Update API URL for custom domain"
git push origin main
```

### **🎊 Result:**
- **Frontend**: `https://yourdomain.com`
- **API**: `https://api.yourdomain.com`
- **SSL**: Automatically handled by Cloudflare

---

## 🏗️ **Option B: AWS Application Load Balancer**

### **Why ALB?**
- ✅ **Native AWS integration**
- ✅ **Better for AWS-heavy setups**
- ✅ **More control over routing**
- ✅ **Health checks**

### **Step 1: Create Application Load Balancer**

```bash
# Create ALB
aws elbv2 create-load-balancer \
  --name todo-app-alb \
  --subnets subnet-073c62d41f5f2f178 subnet-0ffcb129c4743a018 \
  --security-groups sg-032def7bdaffd9850 \
  --scheme internet-facing \
  --type application \
  --ip-address-type ipv4
```

### **Step 2: Create Target Groups**

```bash
# Frontend target group
aws elbv2 create-target-group \
  --name todo-frontend-tg \
  --protocol HTTP \
  --port 3000 \
  --vpc-id vpc-0e2f1b8db99202357 \
  --target-type ip \
  --health-check-path /

# Backend target group  
aws elbv2 create-target-group \
  --name todo-backend-tg \
  --protocol HTTP \
  --port 8000 \
  --vpc-id vpc-0e2f1b8db99202357 \
  --target-type ip \
  --health-check-path /api/todos/
```

### **Step 3: Request SSL Certificate**

```bash
# Request certificate for your domain
aws acm request-certificate \
  --domain-name yourdomain.com \
  --subject-alternative-names "*.yourdomain.com" \
  --validation-method DNS \
  --region us-east-1
```

### **Step 4: Create Listeners**

```bash
# Get ALB ARN from step 1 output
ALB_ARN="arn:aws:elasticloadbalancing:us-east-1:533218240958:loadbalancer/app/todo-app-alb/..."

# Get target group ARNs from step 2 output
FRONTEND_TG_ARN="arn:aws:elasticloadbalancing:us-east-1:533218240958:targetgroup/todo-frontend-tg/..."
BACKEND_TG_ARN="arn:aws:elasticloadbalancing:us-east-1:533218240958:targetgroup/todo-backend-tg/..."

# Create HTTPS listener (after certificate is validated)
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=CERTIFICATE_ARN \
  --default-actions Type=forward,TargetGroupArn=$FRONTEND_TG_ARN

# Create HTTP listener (redirects to HTTPS)
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=redirect,RedirectConfig='{Protocol=HTTPS,Port=443,StatusCode=HTTP_301}'
```

### **Step 5: Update ECS Services**

Update your ECS services to use the target groups instead of public IPs.

---

## 🎯 **Quick Comparison**

| Feature | Cloudflare | AWS ALB |
|---------|------------|---------|
| **Setup Time** | 15 minutes | 1-2 hours |
| **Cost** | Free | ~$20/month |
| **SSL** | Free | Free (via ACM) |
| **Complexity** | Very Easy | Moderate |
| **Performance** | Global CDN | Regional |
| **Best For** | Quick setup | AWS-native |

---

## 🚀 **Recommended Approach: Start with Cloudflare**

For your Todo app, I recommend **Cloudflare** because:

1. **Fastest setup** - Working in 15 minutes
2. **Free SSL** - No additional costs
3. **Better performance** - Global CDN
4. **Easy management** - Simple dashboard
5. **Future-proof** - Can always migrate to ALB later

---

## 📝 **Step-by-Step Cloudflare Setup**

### **1. Get Your IPs**
```bash
./get-website-urls.sh
```

### **2. Sign up for Cloudflare**
- Go to cloudflare.com
- Add your domain

### **3. Add DNS Records**
```
A record: @ → YOUR_FRONTEND_IP (proxied)
A record: api → YOUR_BACKEND_IP (proxied)
```

### **4. Update Nameservers**
- Copy Cloudflare nameservers
- Update at your domain registrar

### **5. Enable SSL**
- SSL/TLS → Full (strict)
- Always Use HTTPS: On

### **6. Update App**
```bash
echo "NEXT_PUBLIC_API_URL=https://api.yourdomain.com" > frontend/.env.production
git add . && git commit -m "Add custom domain" && git push
```

### **7. Test**
- Wait 5-10 minutes for DNS propagation
- Visit `https://yourdomain.com`
- Check `https://api.yourdomain.com/api/todos/`

---

## 🔍 **Troubleshooting**

### **DNS Not Working?**
```bash
# Check DNS propagation
nslookup yourdomain.com
# Should show Cloudflare IPs, not your server IPs
```

### **SSL Errors?**
- Make sure "Proxy" is enabled (orange cloud)
- Check SSL mode is "Full (strict)"
- Wait up to 24 hours for full propagation

### **API Not Working?**
- Verify backend IP is correct
- Check CORS settings in Django
- Ensure API subdomain is proxied

---

## 🎊 **Success!**

When working, you'll have:
- ✅ `https://yourdomain.com` - Your Todo app
- ✅ `https://api.yourdomain.com` - Your API
- ✅ Free SSL certificates
- ✅ Global CDN performance
- ✅ Professional domain setup

**Ready to set this up? Which domain do you want to use?** 