# One-command WhisperX subtitle generation and translation script (Windows PowerShell)

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot

$VideoDir = if ($env:VIDEO_DIR) { $env:VIDEO_DIR } else { "./videos" }
$OutputDir = if ($env:OUTPUT_DIR) { $env:OUTPUT_DIR } else { "./output" }
$TranslatedDir = if ($env:TRANSLATED_DIR) { $env:TRANSLATED_DIR } else { "./translated" }
$TargetLang = if ($env:TARGET_LANG) { $env:TARGET_LANG } else { "zh" }

Write-Host "=================================" -ForegroundColor Green
Write-Host "  WhisperX Subtitle Generation + Translation Tool" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""

# Check dependencies
$PythonCmd = $null
if (Get-Command python3 -ErrorAction SilentlyContinue) {
    $PythonCmd = "python3"
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $ver = & python --version 2>&1
    if ($ver -match "Python 3") {
        $PythonCmd = "python"
    }
}
if (-not $PythonCmd) {
    Write-Host "python3 / python not found" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "ffmpeg not found (required by WhisperX)" -ForegroundColor Red
    Write-Host "   Install with: choco install ffmpeg  or  scoop install ffmpeg"
    exit 1
}

# Create output directories
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
New-Item -ItemType Directory -Force -Path $TranslatedDir | Out-Null

# Step 1: transcription
Write-Host "Step 1: Transcribe video audio into subtitles" -ForegroundColor Yellow
Write-Host ""

& $PythonCmd "$ScriptDir/transcribe.py" $VideoDir -o $OutputDir -m medium
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Transcription completed" -ForegroundColor Green
Write-Host ""

# Step 2: translation (optional)
Write-Host "Step 2: Translate subtitles into target language ($TargetLang)" -ForegroundColor Yellow
Write-Host ""

if (-not $env:OPENAI_API_KEY) {
    Write-Host "OPENAI_API_KEY is not set, skipping translation" -ForegroundColor Yellow
    Write-Host '   To enable translation, run: $env:OPENAI_API_KEY="your_key"'
    Write-Host ""
} else {
    & $PythonCmd "$ScriptDir/translate.py" $OutputDir -o $TranslatedDir `
        -t $TargetLang --bilingual --target-only
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host ""
    Write-Host "Translation completed" -ForegroundColor Green
}

Write-Host ""
Write-Host "=================================" -ForegroundColor Green
Write-Host "  All tasks completed" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""
Write-Host "Output files:"
Write-Host "  - Source subtitles:    $OutputDir/*.{lang}.srt"
Write-Host "  - Bilingual subtitles: $TranslatedDir/*.bilingual.srt"
Write-Host "  - Target subtitles:    $TranslatedDir/*.$TargetLang.srt"
Write-Host ""
