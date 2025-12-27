#!/bin/bash
# Script to run Streamlit app with proper virtual environment

cd "$(dirname "$0")"

# Activate virtual environment
if [ -d "venv" ]; then
    source venv/bin/activate
else
    echo "Virtual environment not found. Creating one..."
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
fi

# Ensure all dependencies are installed
echo "Checking dependencies..."
pip install -q -r requirements.txt

# Run Streamlit
streamlit run app.py

