param(
  [string]$Password = "2400620@SIT.singaporetech.edu.sg",
  [string]$ProjectKey = "ict2216-practical-2400620"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot

function New-BasicHeader([string]$User, [string]$Secret) {
  $bytes = [Text.Encoding]::UTF8.GetBytes("${User}:${Secret}")
  return @{ Authorization = "Basic $([Convert]::ToBase64String($bytes))" }
}

$headers = New-BasicHeader "admin" $Password
$tokenName = "local-scan-2400620"

& npm run test:coverage
if ($LASTEXITCODE -ne 0) {
  throw "Coverage tests failed."
}

try {
  Invoke-RestMethod `
    -Uri "http://127.0.0.1:9000/api/user_tokens/revoke" `
    -Method Post `
    -Headers $headers `
    -ContentType "application/x-www-form-urlencoded" `
    -Body @{ name = $tokenName } |
    Out-Null
} catch {
  # The token does not exist on the first scan.
}

$tokenResponse = Invoke-RestMethod `
  -Uri "http://127.0.0.1:9000/api/user_tokens/generate" `
  -Method Post `
  -Headers $headers `
  -ContentType "application/x-www-form-urlencoded" `
  -Body @{ name = $tokenName; type = "GLOBAL_ANALYSIS_TOKEN" }

$oldToken = $env:SONAR_TOKEN
$oldHostUrl = $env:SONAR_HOST_URL
try {
  $env:SONAR_TOKEN = $tokenResponse.token
  $env:SONAR_HOST_URL = "http://127.0.0.1:9000"
  & sonar-scanner.bat
  if ($LASTEXITCODE -ne 0) {
    throw "SonarScanner failed with exit code $LASTEXITCODE."
  }
} finally {
  $env:SONAR_TOKEN = $oldToken
  $env:SONAR_HOST_URL = $oldHostUrl
}

$taskUrlLine = Get-Content -LiteralPath ".scannerwork/report-task.txt" |
  Where-Object { $_ -like "ceTaskUrl=*" } |
  Select-Object -First 1
if (-not $taskUrlLine) {
  throw "SonarScanner did not create a background task URL."
}
$taskUrl = $taskUrlLine.Substring("ceTaskUrl=".Length)

for ($attempt = 1; $attempt -le 30; $attempt++) {
  $task = (Invoke-RestMethod -Uri $taskUrl -Headers $headers).task
  if ($task.status -eq "SUCCESS") {
    break
  }
  if ($task.status -in @("FAILED", "CANCELED")) {
    throw "SonarQube background analysis failed."
  }
  Start-Sleep -Seconds 2
}
if ($task.status -ne "SUCCESS") {
  throw "SonarQube background analysis timed out."
}

$issues = Invoke-RestMethod `
  -Uri "http://127.0.0.1:9000/api/issues/search?componentKeys=$ProjectKey&types=BUG,VULNERABILITY&resolved=false&ps=1" `
  -Headers $headers
$hotspots = Invoke-RestMethod `
  -Uri "http://127.0.0.1:9000/api/hotspots/search?projectKey=$ProjectKey&status=TO_REVIEW&ps=1" `
  -Headers $headers

$result = [pscustomobject]@{
  BugsAndVulnerabilities = $issues.total
  SecurityHotspotsToReview = $hotspots.paging.total
  Dashboard = "http://127.0.0.1:9000/dashboard?id=$ProjectKey"
}
$result | Format-List

if ($issues.total -ne 0 -or $hotspots.paging.total -ne 0) {
  throw "SonarQube still reports unresolved security or reliability findings."
}
