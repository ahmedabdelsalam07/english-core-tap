# Updates the password of existing Firebase Auth users (no account creation).
# Avoids the rate-limited accounts:signUp endpoint entirely.
#
# Usage:
#   .\update_passwords.ps1 -ApiKey "AIza..." [-CsvPath "users.csv"] [-LegacyPassword "Student123"]

param(
  [Parameter(Mandatory = $true)]
  [string]$ApiKey,

  [string]$CsvPath = "users.csv",
  [string]$LegacyPassword = "Student123",
  [int]$DelayMs = 700
)

function Invoke-FirebasePost {
  param([string]$Endpoint, [string]$JsonBody)
  $uri = "https://identitytoolkit.googleapis.com/v1/$Endpoint`?key=$ApiKey"
  try {
    $resp = Invoke-RestMethod -Method Post -Uri $uri -ContentType "application/json" -Body $JsonBody
    return @{ ok = $true; body = $resp }
  } catch {
    $detail = ''
    $respObj = $_.Exception.Response
    if ($respObj -and $respObj.GetResponseStream()) {
      try {
        $reader = New-Object System.IO.StreamReader($respObj.GetResponseStream())
        $detail = $reader.ReadToEnd()
        $reader.Close()
      } catch {}
    }
    return @{ ok = $false; raw = $detail }
  }
}

$lines = Get-Content -Path $CsvPath
$updated = 0
$failed = 0

foreach ($line in $lines) {
  if ([string]::IsNullOrWhiteSpace($line)) { continue }
  $parts = $line -split ','
  if ($parts.Count -lt 2) { continue }
  $email = $parts[0].Trim()
  $password = $parts[1].Trim()
  if ($email -eq '' -or $password -eq '' -or $email -notmatch '@') { continue }

  $loginBody = @{ email = $email; password = $LegacyPassword; returnSecureToken = $true } | ConvertTo-Json -Compress
  $login = Invoke-FirebasePost -Endpoint "accounts:signInWithPassword" -JsonBody $loginBody
  if ($login.ok -and $login.body.idToken) {
    $updBody = @{ idToken = $login.body.idToken; password = $password } | ConvertTo-Json -Compress
    $upd = Invoke-FirebasePost -Endpoint "accounts:update" -JsonBody $updBody
    if ($upd.ok) { Write-Output "UPDATED: $email"; $updated++ }
    else { Write-Output "FAIL-UPDATE: $email -> $($upd.raw)"; $failed++ }
  } else {
    Write-Output "FAIL-LOGIN: $email -> $($login.raw)"; $failed++
  }
  Start-Sleep -Milliseconds $DelayMs
}

Write-Output ""
Write-Output "Done. Updated: $updated  Failed: $failed"