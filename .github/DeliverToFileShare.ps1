Param([Hashtable]$parameters)

function Get-SettingValue {
    Param(
        [object]$settings,
        [string]$name
    )

    if ($null -eq $settings) {
        return $null
    }

    $property = $settings.PSObject.Properties[$name]
    if ($null -ne $property) {
        return $property.Value
    }

    return $null
}

$projectName = $parameters.projectName
$appsFolder = $parameters.appsFolder
$type = $parameters.type

if ($type -ne "Release") {
    Write-Host "Skipping file share delivery for delivery type '$type'. Only Release is delivered."
    return
}

$fileShareBasePath = Get-SettingValue -settings $parameters.RepoSettings -name 'fileShareBasePath'
$fileSharePath = Get-SettingValue -settings $parameters.ProjectSettings -name 'fileSharePath'

if ([string]::IsNullOrWhiteSpace($fileShareBasePath)) {
    $fileShareBasePath = "\\10.60.0.35\Software\apps"
}

if ([string]::IsNullOrWhiteSpace($fileSharePath)) {
    $fileSharePath = "product"
}

if (@("product", "customers") -notcontains $fileSharePath) {
    throw "Invalid fileSharePath '$fileSharePath'. Allowed values are 'product' and 'customers'."
}

$destination = Join-Path (Join-Path $fileShareBasePath $fileSharePath) $projectName

if (-not (Test-Path $destination)) {
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
}

$appFiles = @(Get-ChildItem -Path $appsFolder -Filter "*.app" -File)
if ($appFiles.Count -eq 0) {
    throw "No .app files found in '$appsFolder'."
}

$appFiles | ForEach-Object {
    Copy-Item $_.FullName -Destination $destination -Force
    Write-Host "Copied $($_.Name) to $destination ($type)"
}

$latestArchive = Join-Path $destination "latest.zip"
Compress-Archive -Path $appFiles.FullName -DestinationPath $latestArchive -Force
Write-Host "Created $latestArchive"