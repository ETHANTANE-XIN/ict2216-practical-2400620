param(
  [string]$Password = "2400620@SIT.singaporetech.edu.sg",
  [string]$SonarPassword = "2400620@SIT.singaporetech.edu.sg",
  [string]$GitEmail = "2400620@sit.singaporetech.edu.sg",
  [string]$ProjectName = "ict2216-practical-2400620"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot

function New-BasicHeader([string]$User, [string]$Secret) {
  $bytes = [Text.Encoding]::UTF8.GetBytes("${User}:${Secret}")
  return @{ Authorization = "Basic $([Convert]::ToBase64String($bytes))" }
}

$giteaUsers = docker compose exec -T --user git git-server `
  gitea admin user list --config /data/gitea/conf/app.ini 2>&1
if ($LASTEXITCODE -ne 0) {
  throw "Could not inspect Gitea users: $giteaUsers"
}

if (($giteaUsers -join "`n") -notmatch "(?m)^\d+\s+admin\s") {
  docker compose exec -T --user git git-server `
    gitea admin user create `
      --config /data/gitea/conf/app.ini `
      --username admin `
      --password $Password `
      --email $GitEmail `
      --admin `
      --must-change-password=false
  if ($LASTEXITCODE -ne 0) {
    throw "Gitea admin creation failed."
  }
}

$giteaHeaders = New-BasicHeader "admin" $Password
try {
  Invoke-RestMethod `
    -Uri "http://127.0.0.1:3001/api/v1/user/repos" `
    -Method Post `
    -Headers $giteaHeaders `
    -ContentType "application/json" `
    -Body (@{ name = $ProjectName; private = $false } | ConvertTo-Json) |
    Out-Null
} catch {
  if ($_.Exception.Response.StatusCode.value__ -ne 409) {
    throw
  }
}

$sonarReady = $false
for ($attempt = 1; $attempt -le 90; $attempt++) {
  try {
    $status = Invoke-RestMethod -Uri "http://127.0.0.1:9000/api/system/status"
    if ($status.status -eq "UP") {
      $sonarReady = $true
      break
    }
  } catch {
    # SonarQube is still starting.
  }
  Start-Sleep -Seconds 2
}
if (-not $sonarReady) {
  throw "SonarQube did not become ready."
}

$newSonarHeaders = New-BasicHeader "admin" $SonarPassword
try {
  $authentication = Invoke-RestMethod `
    -Uri "http://127.0.0.1:9000/api/authentication/validate" `
    -Headers $newSonarHeaders
} catch {
  $authentication = @{ valid = $false }
}

if (-not $authentication.valid) {
  $defaultSonarHeaders = New-BasicHeader "admin" "admin"
  Invoke-RestMethod `
    -Uri "http://127.0.0.1:9000/api/users/change_password" `
    -Method Post `
    -Headers $defaultSonarHeaders `
    -ContentType "application/x-www-form-urlencoded" `
    -Body @{
      login = "admin"
      previousPassword = "admin"
      password = $SonarPassword
    } |
    Out-Null
}

Write-Host "Gitea: http://127.0.0.1:3001/admin/$ProjectName"
Write-Host "SonarQube: http://127.0.0.1:9000"
