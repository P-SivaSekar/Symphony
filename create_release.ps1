$token = $env:GITHUB_TOKEN
$owner = "P-SivaSekar"
$repo = "Symphony"
$tag = "v1.0.0"
$name = "Symphony v1.0.0"
$body = "Initial release of Symphony 1.0.0"
$assetPath = "D:\Studies\Projects\Music Player\Symphony.apk"

Write-Host "Creating release..."
$headers = @{
    Authorization = "Bearer $token"
    Accept = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
    "User-Agent" = "PowerShell-Script"
}

$releaseData = @{
    tag_name = $tag
    name = $name
    body = $body
    draft = $false
    prerelease = $false
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/releases" -Method Post -Headers $headers -Body $releaseData -ContentType "application/json"
    Write-Host "Release created successfully. ID: $($response.id)"
} catch {
    Write-Host "Error creating release: $_"
    if ($_.ErrorDetails) {
        Write-Host "Details: $($_.ErrorDetails.Message)"
    }
    exit 1
}

$uploadUrl = $response.upload_url -replace '\{.*?\}', '?name=Symphony.apk'

Write-Host "Uploading asset to $uploadUrl..."
$assetHeaders = @{
    Authorization = "Bearer $token"
    Accept = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
    "User-Agent" = "PowerShell-Script"
    "Content-Type" = "application/vnd.android.package-archive"
}

try {
    $fileBytes = [System.IO.File]::ReadAllBytes($assetPath)
    Invoke-RestMethod -Uri $uploadUrl -Method Post -Headers $assetHeaders -Body $fileBytes | Out-Null
    Write-Host "Asset uploaded successfully!"
} catch {
    Write-Host "Error uploading asset: $_"
    if ($_.ErrorDetails) {
        Write-Host "Details: $($_.ErrorDetails.Message)"
    }
    exit 1
}
