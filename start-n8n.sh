#!/bin/bash
# Start n8n with all data on D: drive

export N8N_USER_FOLDER="D:/Upwork work/n8n-data"
export N8N_PORT=5678
export N8N_HOST=localhost
export N8N_PROTOCOL=http
export N8N_DIAGNOSTICS_ENABLED=false
export GENERIC_TIMEZONE="America/New_York"

echo "============================================"
echo "  Starting n8n E-Commerce Automation Suite"
echo "============================================"
echo ""
echo "n8n data folder: D:/Upwork work/n8n-data"
echo "Web UI: http://localhost:5678"
echo ""
echo "Press Ctrl+C to stop n8n"
echo ""

cd "D:/Upwork work/n8n-ecommerce"
./node_modules/.bin/n8n start
