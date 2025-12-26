#!/bin/bash

# Script to run dbt commands inside the virtual environment

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Running setup first..."
    ./setup_venv.sh
fi

# Activate virtual environment
source venv/bin/activate

# Set DBT_PROFILES_DIR to current directory so dbt uses local profiles.yml
export DBT_PROFILES_DIR="$SCRIPT_DIR"

# Run dbt with all passed arguments
dbt "$@"

