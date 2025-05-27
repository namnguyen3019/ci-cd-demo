#!/bin/bash

# Domain setup helper script
echo "🌐 Domain Setup Helper"
echo "====================="

# Check if domain is provided
if [ -z "$1" ]; then
    echo "❌ Please provide your domain name"
    echo "Usage: ./setup-domain.sh yourdomain.com"
    exit 1
fi

DOMAIN=$1
echo "🎯 Setting up domain: $DOMAIN"

# Update frontend environment
echo "📝 Updating frontend configuration..."
echo "NEXT_PUBLIC_API_URL=https://api.$DOMAIN" > frontend/.env.production

# Also update the development environment for consistency
echo "NEXT_PUBLIC_API_URL=https://api.$DOMAIN" > frontend/.env.local

echo "✅ Updated frontend to use: https://api.$DOMAIN"

# Update CORS settings in Django
echo "🔧 Updating Django CORS settings..."
cat >> backend/todoproject/settings.py << EOF

# Domain-specific CORS settings
CORS_ALLOWED_ORIGINS = [
    "https://$DOMAIN",
    "https://www.$DOMAIN",
    "http://localhost:3000",  # Keep for local development
]

ALLOWED_HOSTS = [
    "$DOMAIN",
    "www.$DOMAIN", 
    "api.$DOMAIN",
    "localhost",
    "127.0.0.1",
]
EOF

echo "✅ Updated Django CORS and ALLOWED_HOSTS"

# Commit changes
echo "📦 Committing changes..."
git add .
git commit -m "Configure domain: $DOMAIN with SSL"

echo ""
echo "🚀 Next steps:"
echo "1. Set up DNS records in Cloudflare:"
echo "   A record: @   → YOUR_FRONTEND_IP (proxied)"
echo "   A record: api → YOUR_BACKEND_IP (proxied)"
echo "   A record: www → YOUR_FRONTEND_IP (proxied)"
echo ""
echo "2. Update nameservers at your domain registrar"
echo ""
echo "3. Enable SSL in Cloudflare (Full strict mode)"
echo ""
echo "4. Push changes to trigger deployment:"
echo "   git push origin main"
echo ""
echo "5. Your sites will be available at:"
echo "   🎨 Frontend: https://$DOMAIN"
echo "   🔧 API: https://api.$DOMAIN"
echo ""
echo "📖 Full guide: SIMPLE-DOMAIN-SSL-SETUP.md" 