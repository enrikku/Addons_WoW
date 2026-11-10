# Genera Canciones.lua a partir de los archivos de la carpeta Musica.
# Lee la duración de cada canción para que el reproductor pase a la siguiente solo.

$ErrorActionPreference = "Stop"
$base    = Split-Path -Parent $MyInvocation.MyCommand.Path
$carpeta = Join-Path $base "Musica"
$salida  = Join-Path $base "Canciones.lua"

if (-not (Test-Path $carpeta)) {
    New-Item -ItemType Directory -Path $carpeta | Out-Null
}

$archivos = Get-ChildItem -Path $carpeta -File |
    Where-Object { $_.Extension -match '^\.(mp3|ogg)$' } |
    Sort-Object Name

$shell = New-Object -ComObject Shell.Application
$dir   = $shell.Namespace($carpeta)

# Columna "Duración/Length" (suele ser la 27, pero se busca por si acaso)
$col = 27
foreach ($i in 0..350) {
    $h = $dir.GetDetailsOf($null, $i)
    if ($h -match '^(Length|Duraci[oó]n|Duraci[oó]|Longitud)$') { $col = $i; break }
}

function Escapar([string]$s) { return $s.Replace('\', '\\').Replace('"', '\"') }

$lineas    = New-Object System.Collections.Generic.List[string]
$sinDur    = 0
$especiales = 0

foreach ($a in $archivos) {
    $seg = 0
    $txt = $dir.GetDetailsOf($dir.ParseName($a.Name), $col) -replace '[^0-9:]', ''
    if ($txt -match '^\d+:\d{2}:\d{2}$' -or $txt -match '^\d+:\d{2}$') {
        $p = $txt.Split(':') | ForEach-Object { [int]$_ }
        if ($p.Count -eq 3) { $seg = $p[0] * 3600 + $p[1] * 60 + $p[2] }
        else                { $seg = $p[0] * 60 + $p[1] }
    }
    if ($seg -eq 0) { $sinDur++ }
    if ($a.Name -match '[^\x20-\x7E]') { $especiales++ }

    $titulo = [System.IO.Path]::GetFileNameWithoutExtension($a.Name)
    $lineas.Add(('  {{ archivo = "{0}", titulo = "{1}", duracion = {2} }},' -f (Escapar $a.Name), (Escapar $titulo), $seg))
}

$contenido = "-- Generado automáticamente por GenerarLista.bat`r`nMiMusica_Canciones = {`r`n" +
             ($lineas -join "`r`n") + "`r`n}`r`n"
[System.IO.File]::WriteAllText($salida, $contenido, (New-Object System.Text.UTF8Encoding $false))

Write-Host ""
Write-Host "Listo: $($archivos.Count) canciones guardadas en Canciones.lua" -ForegroundColor Green
if ($sinDur -gt 0) {
    Write-Host "Aviso: $sinDur canciones sin duración (no pasarán solas a la siguiente)." -ForegroundColor Yellow
    Write-Host "       Suele pasar con .ogg; convertirlas a .mp3 lo soluciona." -ForegroundColor Yellow
}
if ($especiales -gt 0) {
    Write-Host "Aviso: $especiales archivos tienen acentos o símbolos en el nombre." -ForegroundColor Yellow
    Write-Host "       Si alguna no suena, renómbrala sin acentos ni símbolos." -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Recuerda: si el juego estaba abierto, ciérralo del todo y vuelve a entrar."
