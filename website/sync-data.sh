#!/bin/bash

# Sync data from the parent results directory to the website's public data directory
echo "Syncing benchmark data..."

# Create the data directory if it doesn't exist
mkdir -p public/data

# Copy all JSON files from the results/program_fixer directory
cp ../results/program_fixer/*.json public/data/

echo "Data sync complete!"
echo "Files synced:"
ls -la public/data/
