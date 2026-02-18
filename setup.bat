@echo off
setlocal enabledelayedexpansion

echo.
echo ============================================================
echo   PersonaPlex Local - Automated Setup
echo   https://github.com/aqibmehedi007/PersonaPlex-Aqib-Mehedi
echo ============================================================
echo.

:: ---------------------------------------------------------------
:: Step 1: Check Python
:: ---------------------------------------------------------------
echo [1/6] Checking Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH.
    echo Please install Python 3.9+ from https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation.
    pause
    exit /b 1
)
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYVER=%%i
echo   Found Python %PYVER%

:: ---------------------------------------------------------------
:: Step 2: Install Python Dependencies
:: ---------------------------------------------------------------
echo.
echo [2/6] Installing Python dependencies...
pip install -r requirements.txt
if errorlevel 1 (
    echo ERROR: Failed to install Python dependencies.
    echo Try running: pip install uvicorn fastapi python-multipart requests
    pause
    exit /b 1
)
echo   Python dependencies installed.

:: ---------------------------------------------------------------
:: Step 3: Download moshi.cpp Binaries
:: ---------------------------------------------------------------
echo.
echo [3/6] Downloading moshi.cpp binaries (~500 MB)...

set MOSHI_ZIP=moshi-bin-win-x64-v0.7.0-beta.zip
set MOSHI_URL=https://github.com/Codes4Fun/moshi.cpp/releases/download/v0.7.0-beta/%MOSHI_ZIP%

if exist "moshi_bin\moshi-sts.exe" (
    echo   moshi_bin already exists, skipping download.
    goto :skip_moshi_download
)

if not exist "%MOSHI_ZIP%" (
    echo   Downloading from GitHub releases...
    curl -L -o "%MOSHI_ZIP%" "%MOSHI_URL%"
    if errorlevel 1 (
        echo ERROR: Failed to download moshi.cpp binaries.
        echo Please manually download from:
        echo   https://github.com/Codes4Fun/moshi.cpp/releases
        pause
        exit /b 1
    )
)

echo   Extracting to moshi_bin...
powershell -Command "Expand-Archive -Path '%MOSHI_ZIP%' -DestinationPath 'moshi_bin_temp' -Force"

:: The zip extracts with a subfolder, move contents up
if exist "moshi_bin_temp\moshi-bin-win-x64-v0.7.0-beta" (
    if not exist "moshi_bin" mkdir moshi_bin
    xcopy /E /Y /Q "moshi_bin_temp\moshi-bin-win-x64-v0.7.0-beta\*" "moshi_bin\"
    rmdir /S /Q "moshi_bin_temp"
) else (
    if not exist "moshi_bin" mkdir moshi_bin
    xcopy /E /Y /Q "moshi_bin_temp\*" "moshi_bin\"
    rmdir /S /Q "moshi_bin_temp"
)

echo   moshi.cpp binaries installed.
:skip_moshi_download

:: ---------------------------------------------------------------
:: Step 4: Download PersonaPlex Model (~5 GB)
:: ---------------------------------------------------------------
echo.
echo [4/6] Downloading PersonaPlex model files (~5 GB)...
echo   This may take a while depending on your internet speed.

if not exist "moshi_bin\aria2c.exe" (
    echo ERROR: aria2c.exe not found in moshi_bin.
    echo Please ensure moshi.cpp binaries were downloaded correctly.
    pause
    exit /b 1
)

:: Check if models already downloaded
if exist "moshi_bin\Codes4Fun\personaplex-7b-v1-q4_k-GGUF\model-q4_k.gguf" (
    echo   PersonaPlex model already downloaded, skipping.
    goto :skip_model_download
)

:: Download using aria2c with the included download script
if exist "moshi_bin\Codes4Fun_personaplex-7b-v1-q4_k-GGUF.txt" (
    pushd moshi_bin
    .\aria2c.exe --disable-ipv6 -i Codes4Fun_personaplex-7b-v1-q4_k-GGUF.txt
    popd
) else (
    echo ERROR: Download script not found.
    echo Please check moshi_bin directory for aria2c download scripts.
    pause
    exit /b 1
)

:: Also download the common models (tokenizer + mimi codec)
if not exist "moshi_bin\Codes4Fun\moshi-common\mimi-e351c8d8-125.gguf" (
    if exist "moshi_bin\Codes4Fun_moshi-common.txt" (
        pushd moshi_bin
        .\aria2c.exe --disable-ipv6 -i Codes4Fun_moshi-common.txt
        popd
    )
)

echo   Model files downloaded.
:skip_model_download

:: ---------------------------------------------------------------
:: Step 5: Set Up Model Directory Structure
:: ---------------------------------------------------------------
echo.
echo [5/6] Setting up model directories...

if not exist "models\m" mkdir "models\m"
if not exist "models\moshi-common" mkdir "models\moshi-common"

:: Copy model files to expected locations
if not exist "models\m\model.gguf" (
    if exist "moshi_bin\Codes4Fun\personaplex-7b-v1-q4_k-GGUF\model-q4_k.gguf" (
        echo   Copying model weights...
        copy /Y "moshi_bin\Codes4Fun\personaplex-7b-v1-q4_k-GGUF\model-q4_k.gguf" "models\m\model.gguf"
    )
)

if not exist "models\m\voice.gguf" (
    if exist "moshi_bin\Codes4Fun\personaplex-7b-v1-q4_k-GGUF\voice.gguf" (
        echo   Copying voice embedding...
        copy /Y "moshi_bin\Codes4Fun\personaplex-7b-v1-q4_k-GGUF\voice.gguf" "models\m\voice.gguf"
    )
)

if not exist "models\moshi-common\mimi-e351c8d8-125.gguf" (
    if exist "moshi_bin\Codes4Fun\moshi-common\mimi-e351c8d8-125.gguf" (
        echo   Copying audio codec...
        copy /Y "moshi_bin\Codes4Fun\moshi-common\mimi-e351c8d8-125.gguf" "models\moshi-common\mimi-e351c8d8-125.gguf"
    )
)

if not exist "models\moshi-common\tokenizer_spm_32k_3.model" (
    if exist "moshi_bin\Codes4Fun\moshi-common\tokenizer_spm_32k_3.model" (
        echo   Copying tokenizer...
        copy /Y "moshi_bin\Codes4Fun\moshi-common\tokenizer_spm_32k_3.model" "models\moshi-common\tokenizer_spm_32k_3.model"
    )
)

:: Copy config
if not exist "models\m\config.json" (
    echo   Copying model config...
    copy /Y "configs\model_config.json" "models\m\config.json"
)

echo   Model directories set up.

:: ---------------------------------------------------------------
:: Step 6: Verify Installation
:: ---------------------------------------------------------------
echo.
echo [6/6] Verifying installation...

set SETUP_OK=1

if not exist "moshi_bin\moshi-sts.exe" (
    echo   [FAIL] moshi-sts.exe not found
    set SETUP_OK=0
) else (
    echo   [OK] moshi-sts.exe found
)

if not exist "models\m\model.gguf" (
    echo   [FAIL] PersonaPlex model not found
    set SETUP_OK=0
) else (
    echo   [OK] PersonaPlex model found
)

if not exist "models\m\config.json" (
    echo   [FAIL] Model config not found
    set SETUP_OK=0
) else (
    echo   [OK] Model config found
)

if not exist "models\moshi-common\mimi-e351c8d8-125.gguf" (
    echo   [FAIL] Mimi audio codec not found
    set SETUP_OK=0
) else (
    echo   [OK] Mimi audio codec found
)

if not exist "models\moshi-common\tokenizer_spm_32k_3.model" (
    echo   [FAIL] Tokenizer not found
    set SETUP_OK=0
) else (
    echo   [OK] Tokenizer found
)

echo.
if "%SETUP_OK%"=="1" (
    echo ============================================================
    echo   Setup Complete! 
    echo ============================================================
    echo.
    echo   To start PersonaPlex:
    echo     python server_moshi.py
    echo.
    echo   Then open http://127.0.0.1:8000 in your browser.
    echo.
    echo   Or just run: start_moshi.bat
    echo ============================================================
) else (
    echo ============================================================
    echo   Setup Incomplete - Some files are missing.
    echo   Please check the errors above and try again.
    echo   See README.md for manual setup instructions.
    echo ============================================================
)

echo.
pause
