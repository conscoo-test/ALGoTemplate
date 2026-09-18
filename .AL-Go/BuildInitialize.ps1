Param(
    [Hashtable] $parameters
)

$ErrorActionPreference = "Stop"

$forNavUrlPrefix = "https://www.fornav.com/products/rep/runtime/"
$settings = $env:Settings | ConvertFrom-Json | ConvertTo-HashTable
$installApps = @($settings.installApps)

$forNavAppExists = $installApps | Where-Object {
    $_ -is [string] -and $_.StartsWith($forNavUrlPrefix, [System.StringComparison]::OrdinalIgnoreCase)
}

if (-not $forNavAppExists) {
    Write-Host "No ForNAV runtime dependency found."
    return
}

$project = $parameters.project

if (-not (Get-Command DownloadAndImportBcContainerHelper -ErrorAction SilentlyContinue)) {
    throw "AL-Go function 'DownloadAndImportBcContainerHelper' is not available in BuildInitialize."
}

DownloadAndImportBcContainerHelper

if (-not (Get-Command DetermineArtifactUrl -ErrorAction SilentlyContinue)) {
    throw "AL-Go function 'DetermineArtifactUrl' is not available in BuildInitialize."
}

$settings = AnalyzeRepo `
    -settings $settings `
    -project $project `
    -doNotCheckArtifactSetting `
    -doNotIssueWarnings

$artifactUrl = DetermineArtifactUrl -projectSettings $settings

if ([string]::IsNullOrWhiteSpace($artifactUrl)) {
    throw "Could not resolve a Business Central artifact URL."
}

$artifactMatch = [regex]::Match(
    $artifactUrl,
    '/(?<version>\d+)(?:\.\d+){1,3}/'
)

if (-not $artifactMatch.Success) {
    throw "Could not determine the Business Central version from artifact URL '$artifactUrl'."
}

$bcVersion = $artifactMatch.Groups['version'].Value

Write-Host "Resolved Business Central artifact: $artifactUrl"
Write-Host "Using Business Central version $bcVersion for ForNAV runtime."

$settings.installApps = @(
    foreach ($installApp in $installApps) {
        if ($installApp -is [string] -and
            $installApp.StartsWith($forNavUrlPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            "$forNavUrlPrefix`?bcversion=$bcVersion"
        }
        else {
            $installApp
        }
    }
)

$updatedSettings = $settings | ConvertTo-Json -Depth 99 -Compress
Add-Content -Encoding UTF8 -Path $env:GITHUB_ENV -Value "Settings=$updatedSettings"

Write-Host "ForNAV runtime dependency updated in AL-Go settings."
