# Local static server for the English Core TaP web build.
# Usage:  powershell -ExecutionPolicy Bypass -File run_local.ps1
# Opens:  http://localhost:8080
param(
  [int]$Port = 8080,
  [string]$Root = (Join-Path $PSScriptRoot 'build\web')
)

$Root = [System.IO.Path]::GetFullPath($Root)

$mime = @{
  '.html' = 'text/html; charset=utf-8'
  '.js'   = 'application/javascript; charset=utf-8'
  '.mjs'  = 'application/javascript; charset=utf-8'
  '.css'  = 'text/css; charset=utf-8'
  '.json' = 'application/json'
  '.png'  = 'image/png'
  '.jpg'  = 'image/jpeg'
  '.jpeg' = 'image/jpeg'
  '.gif'  = 'image/gif'
  '.svg'  = 'image/svg+xml'
  '.ico'  = 'image/x-icon'
  '.woff' = 'font/woff'
  '.woff2'= 'font/woff2'
  '.ttf'  = 'font/ttf'
  '.otf'  = 'font/otf'
  '.wasm' = 'application/wasm'
  '.map'  = 'application/json'
  '.txt'  = 'text/plain; charset=utf-8'
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "English Core TaP running at http://localhost:$Port/"
Write-Host "Press Ctrl+C to stop."

function Serve-Request {
  param($ctx)
  try {
    $raw = $ctx.Request.Url.AbsolutePath
    $rel = [Uri]::UnescapeDataString($raw.TrimStart('/')).Replace('/', '\')
    $file = Join-Path $Root $rel
    if (-not $file.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)) {
      $ctx.Response.StatusCode = 403
      $ctx.Response.Close()
      return
    }
    if (Test-Path -LiteralPath $file -PathType Container) {
      $file = Join-Path $file 'index.html'
    }
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
      $file = Join-Path $Root 'index.html'
    }
    $ext = [System.IO.Path]::GetExtension($file).ToLowerInvariant()
    $ct = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
    $bytes = [System.IO.File]::ReadAllBytes($file)
    $ctx.Response.StatusCode = 200
    $ctx.Response.ContentType = $ct
    $ctx.Response.ContentLength64 = $bytes.Length
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $ctx.Response.OutputStream.Close()
  } catch {
    try { $ctx.Response.StatusCode = 500; $ctx.Response.Close() } catch {}
  }
}

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  Serve-Request -ctx $ctx | Out-Null
}