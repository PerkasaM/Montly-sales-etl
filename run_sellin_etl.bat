@echo off
title ETL Sell-In Bulanan
color 0A
echo ============================================
echo   ETL Sell-In Bulanan - Menjalankan script
echo ============================================
echo.

set SCRIPT_PATH=C:\Users\USER\Documents\MEVAL\Generate\selllin\sellin_etl (11).py

python "%SCRIPT_PATH%"

echo.
if %ERRORLEVEL% EQU 0 (
    echo [OK] Script selesai tanpa error.
) else (
    echo [ERROR] Script gagal. Cek pesan error di atas.
)

echo.
pause