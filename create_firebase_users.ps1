# Creates or updates the student accounts in Firebase Auth from a CSV.
#
# Usage:
#   .\create_firebase_users.ps1 -ApiKey "AIza..." [-CsvPath "مستخدمين_الطلاب.csv"] [-LegacyPassword "Student123"]
#
# CSV format (no header line required): email,password
# For a user that already exists, the script signs in with LegacyPassword
# and updates the password to the new random one.
# Uses the Firebase Auth REST API (no Admin SDK / no card / no CLI).

param(
  [Parameter(Mandatory = $true)]
  [string]$ApiKey,

  [string]$CsvPath = "users.csv",

  # Password the existing accounts currently use (before this run).
  [string]$LegacyPassword = "Student123",

  [int]$DelayMs = 1500,
  [int]$MaxRetries = 6
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
$created = 0
$updated = 0
$failed = 0

foreach ($line in $lines) {
  if ([string]::IsNullOrWhiteSpace($line)) { continue }
  $parts = $line -split ','
  if ($parts.Count -lt 2) { continue }
  # Support two layouts:
  #  - email,password        (users.csv)
  #  - number,user,pw,email  (Arabic distribution CSV)
  $email = ''
  $password = ''
  if ($parts.Count -ge 4 -and $parts[3] -match '@') { $email = $parts[3].Trim(); $password = $parts[2].Trim() }
  else { $email = $parts[0].Trim(); $password = $parts[1].Trim() }
  if ($email -eq '' -or $password -eq '' -or $email -notmatch '@') { continue }

  $body = @{ email = $email; password = $password } | ConvertTo-Json -Compress

  $attempt = 0
  $done = $false
  while (-not $done -and $attempt -le $MaxRetries) {
    $attempt++
    $r = Invoke-FirebasePost -Endpoint "accounts:signUp" -JsonBody $body

    if ($r.ok) { Write-Output "CREATED: $email"; $created++; $done = $true }
    elseif ($r.raw -match 'EMAIL_EXISTS') {
      # User exists with the old password -> sign in, then update password.
      $loginBody = @{
        email = $email; password = $LegacyPassword; returnSecureToken = $true
      } | ConvertTo-Json -Compress
      $login = Invoke-FirebasePost -Endpoint "accounts:signInWithPassword" -JsonBody $loginBody
      if ($login.ok -and $login.body.idToken) {
        $updBody = @{ idToken = $login.body.idToken; password = $password } | ConvertTo-Json -Compress
        $upd = Invoke-FirebasePost -Endpoint "accounts:update" -JsonBody $updBody
        if ($upd.ok) { Write-Output "UPDATED: $email"; $updated++; $done = $true }
        else { Write-Output "FAIL-UPDATE: $email -> $($upd.raw)"; $failed++; $done = $true }
      } else {
        Write-Output "FAIL-LOGIN: $email -> $($login.raw)"; $failed++; $done = $true
      }
    }
    elseif ($r.raw -match 'OPERATION_NOT_ALLOWED') {
      Write-Output "ERROR: Email/Password sign-in is NOT enabled in Firebase console."
      exit 1
    }
    elseif ($r.raw -match 'TOO_MANY_ATTEMPTS') {
      $wait = [Math]::Min(60, 10 * $attempt)
      Write-Output "RATE_LIMIT ($email) - waiting $wait s, retry $attempt/$MaxRetries..."
      Start-Sleep -Seconds $wait
    }
    else {
      Write-Output "FAIL: $email -> $($r.raw)"; $failed++; $done = $true
    }
  }
  Start-Sleep -Milliseconds $DelayMs
}

Write-Output ""
Write-Output "Done. Created: $created  Updated: $updated  Failed: $failed"