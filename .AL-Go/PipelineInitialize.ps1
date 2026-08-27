# .AL-Go/PipelineInitialize.ps1
Param([Hashtable] $parameters)

# Skip when not running in GitHub Actions (e.g. localDevEnv.ps1).
# AL-Go can invoke PipelineInitialize.ps1 in local development scenarios
# where CI environment variables like GITHUB_WORKSPACE are not available.
$githubActions = $env:GITHUB_ACTIONS
if ([string]::IsNullOrWhiteSpace($githubActions) -or $githubActions.Trim().ToLowerInvariant() -eq "false") {
    Write-Host "Not running in GitHub Actions. Skipping ALCops analyzer install."
    return
}

$ErrorActionPreference = "Stop"

$outputPath = Join-Path $env:GITHUB_WORKSPACE ".alcops"

Write-Host "Installing ALCops analyzers..."
Write-Host "  Output path: $outputPath"
Write-Host "  Detect using: $env:artifact"

npx --yes @alcops/core download `
    --output $outputPath `
    --detect-using $env:artifact `
    --detect-from bc-artifact

if ($LASTEXITCODE -ne 0) {
    throw "ALCops download failed with exit code $LASTEXITCODE"
}

Write-Host "ALCops analyzers installed successfully."
