# Genera la imagen de 1200x630 que muestran WhatsApp, Twitter, LinkedIn y
# el correo cuando alguien comparte el link. Se dibuja con las fuentes que
# tiene Windows: Georgia hace de serif y Consolas de monoespaciada.

param([string]$Salida)

Add-Type -AssemblyName System.Drawing

$ancho = 1200
$alto  = 630

$papel  = [System.Drawing.ColorTranslator]::FromHtml("#EAE8E3")
$tinta  = [System.Drawing.ColorTranslator]::FromHtml("#23211E")
$suave  = [System.Drawing.ColorTranslator]::FromHtml("#55504A")
$cobre  = [System.Drawing.ColorTranslator]::FromHtml("#A65A2E")
$linea  = [System.Drawing.ColorTranslator]::FromHtml("#C9C4BC")

$bmp = New-Object System.Drawing.Bitmap($ancho, $alto)
$g   = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$g.Clear($papel)

$margen = 82

# --- barra de acento a la izquierda ---
$brochaCobre = New-Object System.Drawing.SolidBrush($cobre)
$g.FillRectangle($brochaCobre, 0, 0, 14, $alto)

# --- ficha superior, en monoespaciada ---
$fMono = New-Object System.Drawing.Font("Consolas", 17, [System.Drawing.FontStyle]::Bold)
$g.DrawString("PANAMA 2023  ·  19 OCT — 2 DIC", $fMono, $brochaCobre, $margen, 74)

# --- titulo ---
# el cuerpo se elige midiendo: se achica hasta que entre en el ancho util,
# asi el titulo nunca se corta contra el borde
$titulo = "Panamá no se vende"
$util = $ancho - $margen - 60
$cuerpo = 82
do {
    $fTitulo = New-Object System.Drawing.Font("Georgia", $cuerpo, [System.Drawing.FontStyle]::Bold)
    $medida = $g.MeasureString($titulo, $fTitulo)
    if ($medida.Width -le $util) { break }
    $fTitulo.Dispose()
    $cuerpo -= 2
} while ($cuerpo -gt 24)

$brochaTinta = New-Object System.Drawing.SolidBrush($tinta)
$g.DrawString($titulo, $fTitulo, $brochaTinta, ($margen - 8), 130)

# --- bajada, en cursiva ---
$fBajada = New-Object System.Drawing.Font("Georgia", 27, [System.Drawing.FontStyle]::Italic)
$brochaSuave = New-Object System.Drawing.SolidBrush($suave)
$formato = New-Object System.Drawing.StringFormat
$caja = New-Object System.Drawing.RectangleF($margen, 285, 900, 130)
$g.DrawString("Cuarenta y cinco días de bloqueos contra un contrato minero aprobado en cuarenta minutos.", $fBajada, $brochaSuave, $caja, $formato)

# --- linea divisoria ---
$lapiz = New-Object System.Drawing.Pen($linea, 1)
$g.DrawLine($lapiz, $margen, 462, ($ancho - $margen), 462)

# --- cifras al pie ---
$fCifra = New-Object System.Drawing.Font("Georgia", 34, [System.Drawing.FontStyle]::Bold)
$fRotulo = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Regular)

$cifras = @(
    @{ n = "3.687"; r = "PROTESTAS" },
    @{ n = "13";    r = "PROVINCIAS Y COMARCAS" },
    @{ n = "5";     r = "MUERTES" },
    @{ n = "164";   r = "FUENTES" }
)
$x = $margen
foreach ($c in $cifras) {
    $g.DrawString($c.n, $fCifra, $brochaCobre, $x, 496)
    $g.DrawString($c.r, $fRotulo, $brochaSuave, ($x + 2), 552)
    $ancho_r = $g.MeasureString($c.r, $fRotulo).Width
    $x += [Math]::Max($ancho_r + 52, 190)
}

# --- pie del proyecto ---
$fPie = New-Object System.Drawing.Font("Consolas", 13, [System.Drawing.FontStyle]::Regular)
$g.DrawString("FONDECYT REGULAR 1240777  ·  REVUELTAS URBANAS EN AMERICA LATINA", $fPie, $brochaSuave, $margen, 592)

$bmp.Save($Salida, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()

Write-Output ("tarjeta escrita: " + $Salida)
