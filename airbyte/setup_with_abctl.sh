#!/bin/bash

# Airbyte Setup Script using Official abctl Tool
# This script installs and sets up Airbyte using the official abctl method

set -e

echo "🚀 Setting up Airbyte Core using official abctl tool..."
echo ""

# Check if abctl is installed
if ! command -v abctl &> /dev/null; then
    echo "📦 Installing abctl..."
    echo ""
    curl -LsfS https://get.airbyte.com | bash -
    
    # Check if installation was successful
    if ! command -v abctl &> /dev/null; then
        echo "❌ Error: abctl installation failed. Please install manually:"
        echo "   curl -LsfS https://get.airbyte.com | bash -"
        exit 1
    fi
    echo "✅ abctl installed successfully"
    echo ""
else
    echo "✅ abctl is already installed"
    echo ""
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

echo "🐳 Installing Airbyte using abctl..."
echo "   This may take up to 30 minutes depending on your internet connection."
echo ""

# Install Airbyte
abctl local install

echo ""
echo "✅ Airbyte installation complete!"
echo ""
echo "📝 Getting default credentials..."
echo ""
abctl local credentials

echo ""
echo "🌐 Access Airbyte at:"
echo "   - Web UI: http://localhost:8000"
echo ""
echo "📋 Useful commands:"
echo "   - View credentials: abctl local credentials"
echo "   - Set password: abctl local credentials --password YourPassword"
echo "   - Stop Airbyte: abctl local stop"
echo "   - Start Airbyte: abctl local start"
echo "   - Uninstall: abctl local uninstall"

