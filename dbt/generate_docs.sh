#!/bin/bash

# Script to generate dbt documentation

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "📚 Generating dbt documentation..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Running setup first..."
    ./setup_venv.sh
fi

# Activate virtual environment
source venv/bin/activate

# Set DBT_PROFILES_DIR to current directory so dbt uses local profiles.yml
export DBT_PROFILES_DIR="$SCRIPT_DIR"

# Generate docs
echo "Running dbt docs generate..."
dbt docs generate

echo ""
echo "✅ Documentation generated successfully!"
echo "📁 Docs are located in: $SCRIPT_DIR/target"
echo ""
echo "To view docs locally, run:"
echo "  ./run_dbt.sh docs serve"
echo ""
echo "Or to build Docker image:"
echo "  docker build -t dbt-docs -f Dockerfile ."

