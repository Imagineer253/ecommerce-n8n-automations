@echo off
echo ============================================
echo   Starting n8n E-Commerce Automation Suite
echo ============================================
echo.
echo n8n data folder: D:\Upwork work\n8n-data
echo Web UI will be available at: http://localhost:5678
echo.
echo Press Ctrl+C to stop n8n
echo.

:: Set environment variables
set N8N_USER_FOLDER=D:\Upwork work\n8n-data
set N8N_PORT=5678
set N8N_HOST=localhost
set N8N_PROTOCOL=http
set N8N_DIAGNOSTICS_ENABLED=false
set GENERIC_TIMEZONE=America/New_York

:: Change to project directory
cd /d "D:\Upwork work\n8n-ecommerce"

:: Start n8n using local node_modules
node_modules\.bin\n8n start

pause
