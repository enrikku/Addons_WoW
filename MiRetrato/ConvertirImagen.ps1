# Convierte imágenes (png, jpg, bmp, gif...) a .tga 256x256 para usar en MiRetrato.
# Uso: arrastra una o varias imágenes encima de ConvertirImagen.bat
#      o ejecútalo sin nada para convertir todo lo que haya en la carpeta Imagenes.

param([string[]]$Archivos)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$base    = Split-Path -Parent $MyInvocation.MyCommand.Path
$carpeta = Join-Path $base "Imagenes"
$TAM     = 256

if (-not (Test-Path $carpeta)) { New-Item -ItemType Directory -Path $carpeta | Out-Null }

if (-not $Archivos -or $Archivos.Count -eq 0) {
    $Archivos = Get-ChildItem -Path $carpeta -File |
        Where-Object { $_.Extension -match '^\.(png|jpe?g|bmp|gif|tiff?)$' } |
        ForEach-Object { $_.FullName }
}

if (-not $Archivos -or $Archivos.Count -eq 0) {
    Write-Host "No hay imagenes que convertir. Pon tus fotos en la carpeta Imagenes o arrastralas sobre ConvertirImagen.bat"
    exit
}

function Guardar-Tga([System.Drawing.Bitmap]$bmp, [string]$ruta) {
    $rect  = New-Object System.Drawing.Rectangle 0, 0, $bmp.Width, $bmp.Height
    $datos = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly,
                           [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $bytes = New-Object byte[] ($bmp.Width * $bmp.Height * 4)
    # Copia fila a fila por si el stride tiene relleno
    for ($y = 0; $y -lt $bmp.Height; $y++) {
        $ptr = [IntPtr]::Add($datos.Scan0, $y * $datos.Stride)
        [System.Runtime.InteropServices.Marshal]::Copy($ptr, $bytes, $y * $bmp.Width * 4, $bmp.Width * 4)
    }
    $bmp.UnlockBits($datos)

    # Cabecera TGA: sin comprimir, 32 bits (BGRA), origen arriba-izquierda
    $cab = New-Object byte[] 18
    $cab[2]  = 2
    $cab[12] = $bmp.Width  -band 0xFF; $cab[13] = ($bmp.Width  -shr 8) -band 0xFF
    $cab[14] = $bmp.Height -band 0xFF; $cab[15] = ($bmp.Height -shr 8) -band 0xFF
    $cab[16] = 32
    $cab[17] = 0x28

    $fs = [System.IO.File]::Create($ruta)
    try {
        $fs.Write($cab, 0, $cab.Length)
        $fs.Write($bytes, 0, $bytes.Length)
    } finally { $fs.Close() }
}

foreach ($archivo in $Archivos) {
    try {
        $orig = [System.Drawing.Image]::FromFile($archivo)
        try {
            # Recorte cuadrado centrado
            $lado = [Math]::Min($orig.Width, $orig.Height)
            $sx = [int](($orig.Width  - $lado) / 2)
            $sy = [int](($orig.Height - $lado) / 2)

            $bmp = New-Object System.Drawing.Bitmap $TAM, $TAM, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            # Evita bordes semitransparentes al reescalar
            $attr = New-Object System.Drawing.Imaging.ImageAttributes
            $attr.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
            $g.DrawImage($orig, (New-Object System.Drawing.Rectangle 0, 0, $TAM, $TAM),
                         $sx, $sy, $lado, $lado, [System.Drawing.GraphicsUnit]::Pixel, $attr)
            $attr.Dispose()
            $g.Dispose()
        } finally { $orig.Dispose() }

        $nombre = [System.IO.Path]::GetFileNameWithoutExtension($archivo) -replace '[^\w\-]', '_'
        $destino = Join-Path $carpeta ($nombre + ".tga")
        Guardar-Tga $bmp $destino
        $bmp.Dispose()
        Write-Host "OK  $nombre.tga   ->  en el juego: /retrato imagen $nombre"
    } catch {
        Write-Host "ERROR con $archivo : $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "Si el juego estaba abierto, haz /reload (las imagenes NUEVAS a veces necesitan reiniciar el juego)."
