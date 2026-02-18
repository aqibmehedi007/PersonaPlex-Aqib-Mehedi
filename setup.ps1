# PersonaPlex Local - Automated Setup Script (PowerShell)
# https://github.com/aqibmehedi007/PersonaPlex-Aqib-Mehedi
#
# Usage: Right-click -> Run with PowerShell
#   or:  powershell -ExecutionPolicy Bypass -File setup.ps1

param(
    [switch]$SkipModelDownload,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# --- Configuration ---
$MOSHI_VERSION = "v0.7.0-beta"
$MOSHI_ZIP = "moshi-bin-win-x64-$MOSHI_VERSION.zip"
$MOSHI_URL = "https://github.com/Codes4Fun/moshi.cpp/releases/download/$MOSHI_VERSION/$MOSHI_ZIP"

# --- Helper Functions ---
function Write-Step {
    param($Number, $Total, $Message)
    Write-Host "`n[$Number/$Total] " -ForegroundColor Cyan -NoNewline
    Write-Host $Message
}

function Write-Ok {
    param($Message)
    Write-Host "  [OK] " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Fail {
    param($Message)
    Write-Host "  [FAIL] " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Write-Info {
    param($Message)
    Write-Host "  $Message" -ForegroundColor DarkGray
}

# --- Banner ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  PersonaPlex Local - Automated Setup" -ForegroundColor White
Write-Host "  https://github.com/aqibmehedi007/PersonaPlex-Aqib-Mehedi" -ForegroundColor DarkGray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$totalSteps = 6

# --- Step 1: Check Python ---
Write-Step 1 $totalSteps "Checking Python installation..."
try {
    $pyVersion = python --version 2>&1
    Write-Ok "Found $pyVersion"
} catch {
    Write-Fail "Python is not installed or not in PATH."
    Write-Host "  Please install Python 3.9+ from https://www.python.org/downloads/" -ForegroundColor Yellow
    Write-Host "  Make sure to check 'Add Python to PATH' during installation." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# --- Step 2: Install Python Dependencies ---
Write-Step 2 $totalSteps "Installing Python dependencies..."
$pipOutput = pip install -r requirements.txt 2>&1
$ec = $LASTEXITCODE
if ($ec -ne 0) {
    Write-Fail "Failed to install Python dependencies (Exit Code: $ec)"
    Write-Host "  Error details:" -ForegroundColor Red
    $pipOutput | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkRed }
    Write-Host "  Try: pip install uvicorn fastapi python-multipart requests" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Ok "Python dependencies installed"

# --- Step 3: Download moshi.cpp Binaries ---
Write-Step 3 $totalSteps "Setting up moshi.cpp binaries (~500 MB)..."

if ((Test-Path "moshi_bin\moshi-sts.exe") -and -not $Force) {
    Write-Ok "moshi_bin already exists, skipping download"
} else {
    if (-not (Test-Path $MOSHI_ZIP)) {
        Write-Info "Downloading from GitHub releases..."
        Write-Info "URL: $MOSHI_URL"
        
        try {
            $ProgressPreference = 'SilentlyContinue'  # Speed up download
            Invoke-WebRequest -Uri $MOSHI_URL -OutFile $MOSHI_ZIP -UseBasicParsing
            $ProgressPreference = 'Continue'
            Write-Ok "Downloaded $MOSHI_ZIP"
        } catch {
            # Fallback to curl
            Write-Info "Trying curl fallback..."
            curl.exe -L -o $MOSHI_ZIP $MOSHI_URL
            if (-not (Test-Path $MOSHI_ZIP)) {
                Write-Fail "Failed to download moshi.cpp binaries"
                Write-Host "  Please download manually from:" -ForegroundColor Yellow
                Write-Host "  https://github.com/Codes4Fun/moshi.cpp/releases" -ForegroundColor Yellow
                Read-Host "Press Enter to exit"
                exit 1
            }
        }
    } else {
        Write-Info "Using existing $MOSHI_ZIP"
    }

    Write-Info "Extracting..."
    if (Test-Path "moshi_bin_temp") { Remove-Item -Recurse -Force "moshi_bin_temp" }
    Expand-Archive -Path $MOSHI_ZIP -DestinationPath "moshi_bin_temp" -Force
    
    # Handle subfolder in zip
    $subFolder = Get-ChildItem "moshi_bin_temp" -Directory | Select-Object -First 1
    if ($subFolder) {
        if (-not (Test-Path "moshi_bin")) { New-Item -ItemType Directory -Path "moshi_bin" | Out-Null }
        Copy-Item -Path "$($subFolder.FullName)\*" -Destination "moshi_bin\" -Recurse -Force
    } else {
        if (-not (Test-Path "moshi_bin")) { New-Item -ItemType Directory -Path "moshi_bin" | Out-Null }
        Copy-Item -Path "moshi_bin_temp\*" -Destination "moshi_bin\" -Recurse -Force
    }
    Remove-Item -Recurse -Force "moshi_bin_temp"
    Write-Ok "moshi.cpp binaries installed"
}

# --- Step 4: Download PersonaPlex Model ---
Write-Step 4 $totalSteps "Downloading PersonaPlex model files (~5 GB)..."

if ($SkipModelDownload) {
    Write-Info "Skipping model download (--SkipModelDownload flag set)"
} elseif ((Test-Path "moshi_bin\Codes4Fun\personaplex-7b-v1-q4_k-GGUF\model-q4_k.gguf") -and -not $Force) {
    Write-Ok "PersonaPlex model already downloaded, skipping"
} else {
    if (-not (Test-Path "moshi_bin\aria2c.exe")) {
        Write-Fail "aria2c.exe not found in moshi_bin"
        Write-Host "  Please ensure moshi.cpp binaries were installed correctly." -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Download PersonaPlex model
    $downloadScript = "moshi_bin\Codes4Fun_personaplex-7b-v1-q4_k-GGUF.txt"
    if (Test-Path $downloadScript) {
        Write-Info "Downloading PersonaPlex model (this may take 10-30 minutes)..."
        Push-Location "moshi_bin"
        & .\aria2c.exe --disable-ipv6 -i "Codes4Fun_personaplex-7b-v1-q4_k-GGUF.txt"
        Pop-Location
        Write-Ok "PersonaPlex model downloaded"
    } else {
        Write-Fail "Download script not found: $downloadScript"
    }

    # Download common models (tokenizer + mimi codec)
    $commonScript = "moshi_bin\Codes4Fun_moshi-common.txt"
    if (-not (Test-Path "moshi_bin\Codes4Fun\moshi-common\mimi-e351c8d8-125.gguf")) {
        if (Test-Path $commonScript) {
            Write-Info "Downloading common model files (tokenizer + audio codec)..."
            Push-Location "moshi_bin"
            & .\aria2c.exe --disable-ipv6 -i "Codes4Fun_moshi-common.txt"
            Pop-Location
            Write-Ok "Common model files downloaded"
        }
    }
}

# --- Step 5: Set Up Directory Structure ---
Write-Step 5 $totalSteps "Setting up model directories..."

# Create directories
@("models\m", "models\moshi-common") | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

# Copy model files
$copies = @(
    @{ Src = "moshi_bin\Codes4Fun\personaplex-7b-v1-q4_k-GGUF\model-q4_k.gguf"; Dst = "models\m\model.gguf"; Label = "model weights" },
    @{ Src = "moshi_bin\Codes4Fun\personaplex-7b-v1-q4_k-GGUF\voice.gguf"; Dst = "models\m\voice.gguf"; Label = "voice embedding" },
    @{ Src = "moshi_bin\Codes4Fun\moshi-common\mimi-e351c8d8-125.gguf"; Dst = "models\moshi-common\mimi-e351c8d8-125.gguf"; Label = "audio codec" },
    @{ Src = "moshi_bin\Codes4Fun\moshi-common\tokenizer_spm_32k_3.model"; Dst = "models\moshi-common\tokenizer_spm_32k_3.model"; Label = "tokenizer" }
)

foreach ($item in $copies) {
    if ((-not (Test-Path $item.Dst)) -or $Force) {
        if (Test-Path $item.Src) {
            Write-Info "Copying $($item.Label)..."
            Copy-Item -Path $item.Src -Destination $item.Dst -Force
        }
    }
}

# Copy config template
if ((-not (Test-Path "models\m\config.json")) -or $Force) {
    if (Test-Path "configs\model_config.json") {
        Write-Info "Copying model config..."
        Copy-Item -Path "configs\model_config.json" -Destination "models\m\config.json" -Force
    }
}

Write-Ok "Model directories configured"

# --- Step 6: Verify Installation ---
Write-Step 6 $totalSteps "Verifying installation..."

$checks = @(
    @{ Path = "moshi_bin\moshi-sts.exe"; Label = "moshi-sts engine" },
    @{ Path = "models\m\model.gguf"; Label = "PersonaPlex model" },
    @{ Path = "models\m\config.json"; Label = "Model config" },
    @{ Path = "models\m\voice.gguf"; Label = "Voice embedding" },
    @{ Path = "models\moshi-common\mimi-e351c8d8-125.gguf"; Label = "Mimi audio codec" },
    @{ Path = "models\moshi-common\tokenizer_spm_32k_3.model"; Label = "Tokenizer" }
)

$allOk = $true
foreach ($check in $checks) {
    if (Test-Path $check.Path) {
        Write-Ok $check.Label
    } else {
        Write-Fail $check.Label
        $allOk = $false
    }
}

# --- Final Status ---
Write-Host ""
if ($allOk) {
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "  Setup Complete!" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  To start PersonaPlex:" -ForegroundColor White
    Write-Host "    python server_moshi.py" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Then open " -NoNewline -ForegroundColor White
    Write-Host "http://127.0.0.1:8000" -ForegroundColor Cyan -NoNewline
    Write-Host " in your browser." -ForegroundColor White
    Write-Host ""
    Write-Host "  Or just run: " -NoNewline -ForegroundColor White
    Write-Host "start_moshi.bat" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
} else {
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host "  Setup Incomplete - Some files are missing." -ForegroundColor Yellow
    Write-Host "  Please check the errors above." -ForegroundColor Yellow
    Write-Host "  See README.md for manual setup instructions." -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow
}

Write-Host ""
Read-Host "Press Enter to exit"
