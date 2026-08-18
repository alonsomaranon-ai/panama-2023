# Lee word/document.xml de un .docx ya descomprimido y lo convierte a un
# formato intermedio de una linea por parrafo:  TIPO|contenido
# Conserva cursivas, negritas, imagenes, hipervinculos y notas al pie.

param(
    [string]$DocDir,
    [string]$Salida
)

$xmlPath  = Join-Path $DocDir "word\document.xml"
$relsPath = Join-Path $DocDir "word\_rels\document.xml.rels"

$xml = New-Object System.Xml.XmlDocument
$xml.PreserveWhitespace = $true
$xml.Load($xmlPath)

$ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
$ns.AddNamespace("w","http://schemas.openxmlformats.org/wordprocessingml/2006/main")
$ns.AddNamespace("r","http://schemas.openxmlformats.org/officeDocument/2006/relationships")
$ns.AddNamespace("a","http://schemas.openxmlformats.org/drawingml/2006/main")

# mapa rId -> archivo de imagen / url de hipervinculo
$rels = New-Object System.Xml.XmlDocument
$rels.Load($relsPath)
$mapa = @{}
foreach ($rel in $rels.DocumentElement.ChildNodes) {
    $mapa[$rel.Id] = $rel.Target
}

function Escapar($t) {
    $t = $t -replace "&","&amp;"
    $t = $t -replace "<","&lt;"
    $t = $t -replace ">","&gt;"
    return $t
}

# Convierte los runs (w:r) de un nodo en HTML con cursivas y negritas
function RunsAHtml($nodo) {
    $sb = New-Object System.Text.StringBuilder
    foreach ($run in $nodo.SelectNodes("descendant-or-self::w:r", $ns)) {
        # imagen dentro del run
        $blip = $run.SelectSingleNode(".//a:blip", $ns)
        if ($blip -ne $null) {
            $rid = $blip.GetAttribute("embed", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
            if ($mapa.ContainsKey($rid)) {
                $archivo = Split-Path $mapa[$rid] -Leaf
                [void]$sb.Append("[[IMG:$archivo]]")
            }
            continue
        }
        # nota al pie
        $nota = $run.SelectSingleNode("w:footnoteReference", $ns)
        if ($nota -ne $null) {
            [void]$sb.Append("[[NOTA:" + $nota.GetAttribute("id","http://schemas.openxmlformats.org/wordprocessingml/2006/main") + "]]")
            continue
        }
        $texto = ""
        foreach ($t in $run.SelectNodes("w:t", $ns))   { $texto += $t.InnerText }
        foreach ($t in $run.SelectNodes("w:tab", $ns))  { $texto += " " }
        foreach ($t in $run.SelectNodes("w:br", $ns))   { $texto += "[[BR]]" }
        if ($texto -eq "") { continue }
        $texto = Escapar $texto
        $rPr = $run.SelectSingleNode("w:rPr", $ns)
        if ($rPr -ne $null) {
            if ($rPr.SelectSingleNode("w:i", $ns)  -ne $null) { $texto = "<em>"     + $texto + "</em>" }
            if ($rPr.SelectSingleNode("w:b", $ns)  -ne $null) { $texto = "<strong>" + $texto + "</strong>" }
        }
        [void]$sb.Append($texto)
    }
    return $sb.ToString()
}

$lineas = New-Object System.Collections.ArrayList
$body = $xml.SelectSingleNode("//w:body", $ns)

foreach ($p in $body.SelectNodes(".//w:p", $ns)) {

    $partes = New-Object System.Text.StringBuilder

    foreach ($hijo in $p.ChildNodes) {
        if ($hijo.LocalName -eq "r") {
            [void]$partes.Append((RunsAHtml $hijo))
        }
        elseif ($hijo.LocalName -eq "sdt") {
            # citas de Mendeley: vienen envueltas en un control de contenido
            $cont = $hijo.SelectSingleNode("w:sdtContent", $ns)
            if ($cont -ne $null) {
                $txt = RunsAHtml $cont
                if ($txt.Trim() -ne "") {
                    [void]$partes.Append('<span class="cita">' + $txt + '</span>')
                }
            }
        }
        elseif ($hijo.LocalName -eq "hyperlink") {
            $rid = $hijo.GetAttribute("id","http://schemas.openxmlformats.org/officeDocument/2006/relationships")
            $txt = RunsAHtml $hijo
            if ($mapa.ContainsKey($rid)) {
                [void]$partes.Append('<a href="' + $mapa[$rid] + '" rel="noopener">' + $txt + '</a>')
            } else {
                [void]$partes.Append($txt)
            }
        }
    }

    $contenido = $partes.ToString().Trim()
    if ($contenido -eq "") { continue }

    # tipo de parrafo
    $tipo = "P"
    $pPr = $p.SelectSingleNode("w:pPr", $ns)
    if ($pPr -ne $null) {
        $estilo = $pPr.SelectSingleNode("w:pStyle", $ns)
        if ($estilo -ne $null) {
            $val = $estilo.GetAttribute("val","http://schemas.openxmlformats.org/wordprocessingml/2006/main")
            if ($val -eq "Ttulo1") { $tipo = "H1" }
            if ($val -eq "Ttulo2") { $tipo = "H2" }
            if ($val -like "TDC*" -or $val -eq "TtuloTDC") { $tipo = "TDC" }
        }
        if ($pPr.SelectSingleNode("w:numPr", $ns) -ne $null) { $tipo = "LI" }
    }

    # un salto de linea manual dentro del parrafo cuenta como parrafo aparte
    foreach ($frag in ($contenido -split "\[\[BR\]\]")) {
        $frag = $frag.Trim()
        if ($frag -ne "") { [void]$lineas.Add("$tipo|$frag") }
    }
}

$lineas | Out-File -FilePath $Salida -Encoding utf8
Write-Output ("Parrafos: " + $lineas.Count)
