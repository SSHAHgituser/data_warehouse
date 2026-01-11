#!/bin/bash
# Script to extract ontology from dbt schema YAML files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Setting up virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

source venv/bin/activate

echo "Installing dependencies..."
pip install --quiet -q rdflib pyyaml

echo "Running ontology extraction..."
python3 extract_ontology.py

echo ""
echo "✓ Ontology extraction complete!"
echo "  Output file: adventureworks_ontology.ttl"
