# Creates the student accounts in Firebase Auth from firebase_users.csv.
#
# Usage:
#   .\create_firebase_users.ps1 -ApiKey "AIza..." [-CsvPath "firebase_users.csv"]
#
# The CSV format is: email,password  (one account per line, no header).
# Uses the Firebase Auth REST API (no Admin SDK / no card / no CLI needed).

param(
  [Parameter(Mandatory = $true)]
  [string]$ApiKey,

  [string]$CsvPath = "firebase_users.csv",

  # Small pause between requests to stay well under rate limits.
  [int]$DelayMs = 400
)

$uri = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$ApiKey"
$lines = Get-Content -Path $CsvPath
$ok = 0
$fail = 0

foreach ($line in $lines) {
  if ([string]::IsNullOrWhiteSpace($line)) { continue }
  $parts = $line -split ','
  if ($parts.Count -lt 2) {
    Write-Host "SKIP (bad line): $line"
    continue
  }
  $email = $parts[0].Trim()
  $password = $parts[1].Trim()
  if ($email -eq '' -or $password -eq '') {
    Write-Host "SKIP (empty): $line"
    continue
  }

  $body = @{ email = $email; password = $password } | ConvertTo-Json -Compress
  try {
    $resp = Invoke-RestMethod -Method Post -Uri $uri -ContentType "application/json" -Body $body
    Write-Host "OK: $email"
    $ok++
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
    $msg = $detail
    if ($msg -match 'EMAIL_EXISTS') {
      Write-Host "EXISTS (skip): $email"
      $ok++
    } elseif ($msg -match 'OPERATION_NOT_ALLOWED') {
      Write-Host "ERROR: Email/Password sign-in is NOT enabled in Firebase console. Enable it first."
      exit 1
    } else {
      Write-Host "FAIL: $email -> $msg"
      $fail++
    }
  }
  Start-Sleep -Milliseconds $DelayMs
}

Write-Host ""
Write-Host "Done. Created/skipped: $ok   Failed: $fail"