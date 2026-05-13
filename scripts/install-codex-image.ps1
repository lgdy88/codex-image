param(
  [string]$Repo = "lgdy88/codex-image",
  [string]$Ref = "main",
  [string]$SourcePath = "",
  [string]$CodexHome = "",
  [switch]$SkipConfigure
)

$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  Write-Host "[codex-image] $Message"
}

function Get-CodexHome {
  if ($CodexHome) {
    $resolved = Resolve-Path -LiteralPath $CodexHome -ErrorAction SilentlyContinue
    if ($resolved) {
      return $resolved.Path
    }
    return $CodexHome
  }
  if ($env:CODEX_HOME) {
    return $env:CODEX_HOME
  }
  return Join-Path $env:USERPROFILE ".codex"
}

function Copy-SkillTree {
  param(
    [string]$Source,
    [string]$Destination
  )

  if (-not (Test-Path -LiteralPath (Join-Path $Source "SKILL.md"))) {
    throw "source path does not look like a codex-image skill: $Source"
  }

  $skillsRoot = Split-Path -Parent $Destination
  New-Item -ItemType Directory -Force -Path $skillsRoot | Out-Null

  if (Test-Path -LiteralPath $Destination) {
    $backupRoot = Join-Path $skillsRoot ".disabled"
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss-ffff"
    $backup = Join-Path $backupRoot "codex-image-backup-$stamp"
    New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
    Copy-Item -LiteralPath $Destination -Destination $backup -Recurse -Force
    Write-Step "backup created: $backup"

    $resolvedDestination = (Resolve-Path -LiteralPath $Destination).Path
    $resolvedSkillsRoot = (Resolve-Path -LiteralPath $skillsRoot).Path
    if (-not $resolvedDestination.StartsWith($resolvedSkillsRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
      throw "refusing to remove unexpected destination: $resolvedDestination"
    }
    Get-ChildItem -LiteralPath $Destination -Force | Remove-Item -Recurse -Force
  } else {
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
  }

  Get-ChildItem -LiteralPath $Source -Force |
    Where-Object { $_.Name -ne "__pycache__" -and $_.Name -ne ".pytest_cache" } |
    ForEach-Object {
      Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force
    }

  Get-ChildItem -LiteralPath $Destination -Recurse -File |
    Where-Object { $_.FullName -match "\\__pycache__\\|\\.pytest_cache\\" -or $_.Extension -eq ".pyc" } |
    Remove-Item -Force
}

function Install-FromGitHub {
  param(
    [string]$Repository,
    [string]$GitRef,
    [string]$Destination
  )

  $workRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-image-install-" + [System.Guid]::NewGuid().ToString("N"))
  New-Item -ItemType Directory -Force -Path $workRoot | Out-Null
  try {
    $zipPath = Join-Path $workRoot "repo.zip"
    $extractPath = Join-Path $workRoot "repo"
    $zipUrl = "https://github.com/$Repository/archive/refs/heads/$GitRef.zip"
    Write-Step "downloading $zipUrl"
    Invoke-WebRequest -UseBasicParsing -Uri $zipUrl -OutFile $zipPath
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force

    $skillSource = Get-ChildItem -LiteralPath $extractPath -Directory |
      Select-Object -First 1 |
      ForEach-Object { Join-Path $_.FullName "skills/codex-image" }
    Copy-SkillTree -Source $skillSource -Destination $Destination
  } finally {
    Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}

function Test-ConfigExists {
  param([string]$CodexHomePath)
  $configPath = Join-Path $CodexHomePath "codex-image/config.json"
  return (Test-Path -LiteralPath $configPath)
}

function Read-RequiredValue {
  param([string]$Prompt)
  $value = Read-Host $Prompt
  if (-not $value.Trim()) {
    throw "$Prompt is required"
  }
  return $value.Trim()
}

function Read-OptionalValue {
  param(
    [string]$Prompt,
    [string]$Default
  )
  $value = Read-Host "$Prompt [$Default]"
  if (-not $value.Trim()) {
    return $Default
  }
  return $value.Trim()
}

function Write-PrivateConfig {
  param([string]$CodexHomePath)

  $baseUrl = Read-RequiredValue -Prompt "OPENAI-compatible base URL"
  $apiKey = Read-RequiredValue -Prompt "API key"
  $model = Read-OptionalValue -Prompt "Model" -Default "gpt-image-2"
  $configPath = Join-Path $CodexHomePath "codex-image/config.json"
  $configDir = Split-Path -Parent $configPath
  New-Item -ItemType Directory -Force -Path $configDir | Out-Null

  $payload = [ordered]@{
    base_url = $baseUrl.TrimEnd("/")
    api_key = $apiKey
    model = $model
  }
  $json = ($payload | ConvertTo-Json) + [Environment]::NewLine
  $utf8NoBom = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($configPath, $json, $utf8NoBom)

  Write-Host "codex-image config saved: $configPath"
  Write-Host "WARNING: API key is shown in plain text because configure was requested to echo it."
  Write-Host "OPENAI-compatible base URL: $($baseUrl.TrimEnd('/'))"
  Write-Host "API key: $apiKey"
  Write-Host "Model: $model"
}

$codexHomePath = Get-CodexHome
$destination = Join-Path $codexHomePath "skills/codex-image"
Write-Step "target: $destination"

if ($SourcePath) {
  $resolvedSource = (Resolve-Path -LiteralPath $SourcePath).Path
  Write-Step "installing from local source: $resolvedSource"
  Copy-SkillTree -Source $resolvedSource -Destination $destination
} else {
  Install-FromGitHub -Repository $Repo -GitRef $Ref -Destination $destination
}

$launcher = Join-Path $destination "scripts/codex-image.cmd"
if (-not (Test-Path -LiteralPath $launcher)) {
  throw "installed launcher not found: $launcher"
}

Write-Step "installed/updated codex-image"

if ($SkipConfigure) {
  Write-Step "configuration skipped"
  exit 0
}

if (Test-ConfigExists -CodexHomePath $codexHomePath) {
  $answer = Read-Host "codex-image is already configured. Update configuration? [y/N]"
  if ($answer -notmatch "^(y|yes)$") {
    Write-Step "configuration unchanged"
    Write-Step "restart Codex Desktop to pick up updated skill files"
    exit 0
  }
}

Write-PrivateConfig -CodexHomePath $codexHomePath

Write-Step "restart Codex Desktop to pick up updated skill files"
