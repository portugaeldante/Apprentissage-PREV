# Serveur local pour "VHP - Apprendre la prevention".
# Sert ce dossier sur http://localhost:8770 et ouvre le navigateur.
# IMPORTANT : ouvre l'app en http:// (et non file://) -> la progression est sauvegardee.
$root = $PSScriptRoot
$port = 8770
$url  = "http://localhost:$port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)
try { $listener.Start() }
catch {
  # Port deja pris = l'app tourne probablement deja : on ouvre juste le navigateur.
  $deja = $false
  try { (Invoke-WebRequest -Uri ($url + 'index.html') -UseBasicParsing -TimeoutSec 3) | Out-Null; $deja = $true } catch {}
  if ($deja) { Write-Host "Deja en cours sur $url - ouverture du navigateur..." -ForegroundColor Green; Start-Process $url; exit 0 }
  Write-Host "Impossible de demarrer sur $url" -ForegroundColor Red
  Write-Host $_.Exception.Message
  Read-Host "Appuyez sur Entree pour fermer"
  exit 1
}
Write-Host ""
Write-Host "  =======================================================" -ForegroundColor Cyan
Write-Host "   Apprentissage VHP demarre :  $url" -ForegroundColor Green
Write-Host "   Laissez cette fenetre OUVERTE pendant l'utilisation." -ForegroundColor Yellow
Write-Host "   Pour arreter : fermez simplement cette fenetre." -ForegroundColor Yellow
Write-Host "  =======================================================" -ForegroundColor Cyan
Write-Host ""
Start-Process $url
$mime = @{
  '.html'='text/html; charset=utf-8'; '.htm'='text/html; charset=utf-8';
  '.js'='application/javascript; charset=utf-8'; '.css'='text/css; charset=utf-8';
  '.json'='application/json; charset=utf-8'; '.webmanifest'='application/manifest+json; charset=utf-8';
  '.png'='image/png'; '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'; '.gif'='image/gif';
  '.svg'='image/svg+xml'; '.ico'='image/x-icon'; '.woff2'='font/woff2'
}
$rootFull = [System.IO.Path]::GetFullPath($root)
$sep = [System.IO.Path]::DirectorySeparatorChar
while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $rel = [System.Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath).TrimStart('/')
    if ([string]::IsNullOrWhiteSpace($rel)) { $rel = 'index.html' }
    # Fichier statique avec protection path-traversal (le chemin resolu DOIT rester sous la racine).
    $full = [System.IO.Path]::GetFullPath((Join-Path $root $rel))
    if (Test-Path -LiteralPath $full -PathType Container) { $full = [System.IO.Path]::GetFullPath((Join-Path $full 'index.html')) }
    if (($full -ne $rootFull) -and (-not $full.StartsWith($rootFull + $sep, [System.StringComparison]::OrdinalIgnoreCase))) {
      $ctx.Response.StatusCode = 403
      $msg = [System.Text.Encoding]::UTF8.GetBytes('403 - acces refuse')
      $ctx.Response.OutputStream.Write($msg, 0, $msg.Length)
    }
    elseif (Test-Path -LiteralPath $full -PathType Leaf) {
      $bytes = [System.IO.File]::ReadAllBytes($full)
      $ext = [System.IO.Path]::GetExtension($full).ToLowerInvariant()
      if ($mime.ContainsKey($ext)) { $ctx.Response.ContentType = $mime[$ext] }
      $ctx.Response.Headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
      $ctx.Response.ContentLength64 = $bytes.Length
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $ctx.Response.StatusCode = 404
      $msg = [System.Text.Encoding]::UTF8.GetBytes('404 - fichier introuvable')
      $ctx.Response.OutputStream.Write($msg, 0, $msg.Length)
    }
    $ctx.Response.OutputStream.Close()
  } catch { }
}
