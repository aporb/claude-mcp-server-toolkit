#!/bin/bash

echo "🔧 GitHub MCP Server Token Setup"
echo "================================="
echo ""

# Check if .env file exists
if [ -f ".env" ]; then
    echo "✅ .env file found"
    source .env
else
    echo "❌ .env file not found"
    echo ""
    echo "Please create a .env file from the template:"
    echo "  cp .env.template .env"
    echo "  nano .env"
    echo ""
    echo "Then add your GitHub Personal Access Token to the .env file."
    echo ""
    echo "To create a GitHub token:"
    echo "1. Go to https://github.com/settings/tokens"
    echo "2. Click 'Generate new token (classic)'"
    echo "3. Select scopes: repo, read:user, read:org"
    echo "4. Copy the token and paste it in .env file"
    echo ""
    exit 1
fi

# Check if token is set
if [ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" ] || [ "$GITHUB_PERSONAL_ACCESS_TOKEN" = "your_github_token_here" ]; then
    echo "❌ GitHub token not set in .env file"
    echo "Please edit .env and set GITHUB_PERSONAL_ACCESS_TOKEN"
    exit 1
fi

# Test token validity
echo "🔍 Testing GitHub token..."
RESPONSE=$(curl -s -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN" https://api.github.com/user)

if echo "$RESPONSE" | grep -q '"login"'; then
    USERNAME=$(echo "$RESPONSE" | grep '"login"' | cut -d'"' -f4)
    echo "✅ GitHub token is valid! Authenticated as: $USERNAME"
    
    # Test token permissions
    echo ""
    echo "🔍 Testing token permissions..."
    
    # Test repo access
    REPOS_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN" https://api.github.com/user/repos?per_page=1)
    if echo "$REPOS_RESPONSE" | grep -q '"name"'; then
        echo "✅ Token has repository access"
    else
        echo "⚠️  Token may not have repository access"
    fi
    
    # Test user read access
    if echo "$RESPONSE" | grep -q '"email"'; then
        echo "✅ Token has user read access"
    else
        echo "⚠️  Token may not have user read access"
    fi
    
    echo ""
    echo "🚀 Ready to configure GitHub MCP server!"
    
else
    echo "❌ GitHub token is invalid or expired"
    echo ""
    echo "Error response:"
    echo "$RESPONSE"
    echo ""
    echo "Please check your token and try again."
    echo "You may need to generate a new token at: https://github.com/settings/tokens"
    exit 1
fi
