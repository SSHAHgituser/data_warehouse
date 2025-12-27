#!/bin/bash
# Script to set up and run Streamlit app with proper virtual environment

set -e

cd "$(dirname "$0")"

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "🐍 Creating virtual environment..."
    python3 -m venv venv
    echo "✅ Virtual environment created"
else
    echo "✓ Virtual environment already exists"
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --quiet --upgrade pip

# Install/update dependencies
echo "Installing dependencies..."
pip install --quiet -r requirements.txt

echo ""
echo "✅ Setup complete! Starting Streamlit..."
echo ""

# Run Streamlit
streamlit run app.py

