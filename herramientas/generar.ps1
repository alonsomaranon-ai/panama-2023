# Toma el archivo intermedio (TIPO|contenido, una linea por parrafo) y
# escribe las cinco paginas HTML del sitio.

param(
    [string]$Intermedio,
    [string]$Destino
)

$ErrorActionPreference = "Stop"

# direccion publica del sitio: las etiquetas para compartir necesitan
# direcciones absolutas, no relativas
$base = "https://alonsomaranon-ai.github.io/panama-2023/"

# ---------- lectura ----------
$crudo = Get-Content -Path $Intermedio -Encoding UTF8
$items = New-Object System.Collections.ArrayList
foreach ($l in $crudo) {
    $l = $l -replace "^﻿",""
    if ($l.Trim() -eq "") { continue }
    $i = $l.IndexOf("|")
    if ($i -lt 0) { continue }
    $tipo = $l.Substring(0, $i)
    $html = $l.Substring($i + 1)
    if ($tipo -eq "TDC") { continue }
    [void]$items.Add(@{ tipo = $tipo; html = $html })
}

function SoloTexto($h) {
    $t = $h -replace "<[^>]+>",""
    $t = $t -replace "&amp;","&"
    return $t.Trim()
}

# ---------- clasificacion ----------
$mesCorto = @{ "Octubre" = "oct"; "Noviembre" = "nov"; "Diciembre" = "dic" }

function EsPregunta($h) {
    return (SoloTexto $h) -match "^(\d)\.(\d{1,2})[\s\. ]"
}
function EsDia($h) {
    return (SoloTexto $h) -match "^(\d{1,2})(\s*[-–]\s*(\d{1,2}))?\s+de\s+(Octubre|Noviembre|Diciembre)\s*$"
}
function EsSemana($h) {
    return (SoloTexto $h) -match "semana:"
}
function EsSinInfo($h) {
    return (SoloTexto $h) -match "^No (se encontr|hubo) informaci"
}

# ---------- render de un tramo ----------
# Devuelve un hashtable con: html (string) y riel (string)
function Render($lista) {

    $sb   = New-Object System.Text.StringBuilder
    $riel = New-Object System.Text.StringBuilder
    $preg = New-Object System.Collections.ArrayList
    $enDia = $false
    $semanaN = 0

    # En el Word, 224 parrafos estan marcados con estilo de lista, pero casi
    # todos son prosa corrida: Word arrastra ese estilo al pegar texto. Poner
    # vinetas en el 60% del informe seria ruido. Se consideran listas de
    # verdad solo las rachas de 3 o mas parrafos LI cortos y seguidos.
    $esItem = New-Object 'System.Collections.Generic.HashSet[int]'
    $racha = New-Object System.Collections.ArrayList
    for ($k = 0; $k -le $lista.Count; $k++) {
        $corto = $false
        if ($k -lt $lista.Count -and $lista[$k].tipo -eq "LI") {
            $palabras = ((SoloTexto $lista[$k].html) -split "\s+").Count
            if ($palabras -lt 45) { $corto = $true }
        }
        if ($corto) { [void]$racha.Add($k) }
        else {
            if ($racha.Count -ge 3) { foreach ($i in $racha) { [void]$esItem.Add($i) } }
            $racha.Clear()
        }
    }
    $enLista = $false

    for ($k = 0; $k -lt $lista.Count; $k++) {

        $tipo = $lista[$k].tipo
        $html = $lista[$k].html
        $txt  = SoloTexto $html

        if ($enLista -and -not $esItem.Contains($k)) {
            [void]$sb.AppendLine('    </ul>')
            $enLista = $false
        }

        # --- imagen (+ su linea "Fuente:" que viene despues) ---
        if ($html -match "\[\[IMG:([^\]]+)\]\]") {
            $archivo = $matches[1]
            $pie = ""
            if ($k + 1 -lt $lista.Count) {
                $sig = SoloTexto $lista[$k + 1].html
                if ($sig -match "^Fuente:") {
                    $pie = $lista[$k + 1].html
                    $k++
                }
            }
            if ($enDia) { [void]$sb.AppendLine("      </div>`n    </div>"); $enDia = $false }
            [void]$sb.AppendLine('    <figure>')
            [void]$sb.AppendLine('      <img src="imagenes/' + $archivo + '" alt="Gráfico del informe" loading="lazy">')
            if ($pie -ne "") { [void]$sb.AppendLine('      <figcaption>' + $pie + '</figcaption>') }
            [void]$sb.AppendLine('    </figure>')
            continue
        }

        # --- titulo de seccion (SECCION 1/2/3, BIBLIOGRAFIA) ---
        if ($tipo -eq "H2") { continue }   # ya va en el encabezado de la pagina

        # --- subtitulo (Inicio, Desarrollo, Desenlace) ---
        if ($tipo -eq "H1") {
            if ($enDia) { [void]$sb.AppendLine("      </div>`n    </div>"); $enDia = $false }
            $id = ($txt.ToLower() -replace "[^a-z0-9]+","-").Trim("-")
            [void]$sb.AppendLine('    <h2 id="' + $id + '">' + $txt + '</h2>')
            continue
        }

        # --- semana ---
        if (EsSemana $html) {
            if ($enDia) { [void]$sb.AppendLine("      </div>`n    </div>"); $enDia = $false }
            $semanaN++
            $partes = $txt -split ":", 2
            $rotulo = $partes[0].Trim()
            $rango  = ""
            if ($partes.Count -gt 1) { $rango = $partes[1].Trim() }
            $id = "semana-$semanaN"
            [void]$sb.AppendLine('    <h2 class="semana" id="' + $id + '">' + $rotulo + ' <span>' + $rango + '</span></h2>')
            [void]$riel.AppendLine('      <div class="riel-semana">' + $rotulo + '</div>')
            continue
        }

        # --- dia de la cronologia ---
        if (EsDia $html) {
            if ($enDia) { [void]$sb.AppendLine("      </div>`n    </div>") }
            $null = $txt -match "^(\d{1,2})(\s*[-–]\s*(\d{1,2}))?\s+de\s+(Octubre|Noviembre|Diciembre)"
            $d1 = $matches[1]
            $d2 = $matches[3]
            $mes = $mesCorto[$matches[4]]
            if ($d2) { $numero = $d1 + "–" + $d2; $id = "d-$d1-$d2-$mes" }
            else     { $numero = $d1;             $id = "d-$d1-$mes" }
            [void]$sb.AppendLine('    <div class="dia" id="' + $id + '">')
            [void]$sb.AppendLine('      <div class="sello"><b>' + $numero + '</b>' + $mes + '</div>')
            [void]$sb.AppendLine('      <div class="dia-texto">')
            [void]$riel.AppendLine('      <a href="#' + $id + '">' + $numero + ' ' + $mes + '</a>')
            $enDia = $true
            continue
        }

        # --- pregunta del template ---
        if (EsPregunta $html) {
            if ($enDia) { [void]$sb.AppendLine("      </div>`n    </div>"); $enDia = $false }
            $null = $txt -match "^(\d)\.(\d{1,2})"
            $codigo = $matches[1] + "." + $matches[2]
            $id = "p" + $matches[1] + "-" + $matches[2]
            # saco el numero del principio del texto de la pregunta
            $sinNumero = $html -replace "^(<[^>]+>)*\s*\d\.\d{1,2}[\s\. ]+", ""
            # rotulo corto para el indice: lo que va antes de los dos puntos
            # si es breve, y si no las primeras palabras de la pregunta
            $plano = SoloTexto $sinNumero
            $rot = $plano
            # corta en los dos puntos o en el punto, lo que venga primero
            $dosp = -1
            foreach ($sep in @(":", ".")) {
                $pos = $plano.IndexOf($sep)
                if ($pos -gt 2 -and $pos -le 42) {
                    if ($dosp -lt 0 -or $pos -lt $dosp) { $dosp = $pos }
                }
            }
            if ($dosp -gt 2) {
                $rot = $plano.Substring(0, $dosp)
            } elseif ($plano.Length -gt 52) {
                $corte = $plano.Substring(0, 52).LastIndexOf(" ")
                if ($corte -lt 20) { $corte = 52 }
                $rot = $plano.Substring(0, $corte) + "…"
            }
            [void]$preg.Add(@{ codigo = $codigo; id = $id; rotulo = $rot })

            [void]$sb.AppendLine('    <div class="pregunta" id="' + $id + '">')
            [void]$sb.AppendLine('      <span class="codigo">' + $codigo + '</span>')
            [void]$sb.AppendLine('      <h3>' + $sinNumero + '<a class="ancla" href="#' + $id + '" aria-label="Enlace a esta pregunta">#</a></h3>')
            [void]$sb.AppendLine('    </div>')
            continue
        }

        # --- parrafos ---
        if ($txt -eq "---") {
            [void]$sb.AppendLine('    <p class="sin-info">—</p>')
            continue
        }
        if (EsSinInfo $html) {
            [void]$sb.AppendLine('    <p class="sin-info">' + $html + '</p>')
            continue
        }
        if ($esItem.Contains($k)) {
            if (-not $enLista) { [void]$sb.AppendLine('    <ul class="lista">'); $enLista = $true }
            [void]$sb.AppendLine('      <li>' + $html + '</li>')
            continue
        }
        if ($enDia) {
            [void]$sb.AppendLine('        <p>' + $html + '</p>')
        } else {
            [void]$sb.AppendLine('    <p>' + $html + '</p>')
        }
    }

    if ($enLista) { [void]$sb.AppendLine('    </ul>') }
    if ($enDia) { [void]$sb.AppendLine("      </div>`n    </div>") }

    return @{ html = $sb.ToString(); riel = $riel.ToString(); preguntas = $preg }
}

# ---------- indice de preguntas ----------
# Va arriba de las secciones 1 y 3, que son las que se organizan por
# preguntas. La cronologia no lo lleva: alli el buscador y el riel de
# fechas ya cumplen esa funcion, y un indice mas seria estorbo.
function IndicePreguntas($preguntas, $titulo) {
    if ($preguntas.Count -eq 0) { return "" }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('    <nav class="indice-preguntas">')
    [void]$sb.AppendLine('      <div class="rotulo">' + $titulo + '</div>')
    [void]$sb.AppendLine('      <ul>')
    foreach ($p in $preguntas) {
        $rot = $p.rotulo -replace "&","&amp;"
        [void]$sb.AppendLine('        <li><a href="#' + $p.id + '"><b>' + $p.codigo + '</b> ' + $rot + '</a></li>')
    }
    [void]$sb.AppendLine('      </ul>')
    [void]$sb.AppendLine('    </nav>')
    return $sb.ToString()
}

# ---------- particion en paginas ----------
function IndiceDe($patron) {
    for ($i = 0; $i -lt $items.Count; $i++) {
        if ($items[$i].tipo -eq "H2" -and (SoloTexto $items[$i].html) -match $patron) { return $i }
    }
    return -1
}

$iS1 = IndiceDe "^SECCIÓN 1"
$iS2 = IndiceDe "^SECCIÓN 2"
$iS3 = IndiceDe "^SECCIÓN 3"
$iBi = IndiceDe "^BIBLIOGRAF"

$tramoS1 = $items[$iS1..($iS2 - 1)]
$tramoS2 = $items[$iS2..($iS3 - 1)]
$tramoS3 = $items[$iS3..($iBi - 1)]
$tramoBi = $items[($iBi + 1)..($items.Count - 1)]

# ---------- plantilla ----------
function Pagina($archivo, $titulo, $descripcion, $ficha, $h1, $bajada, $cuerpo, $paso) {

    $nav = ""
    $paginas = @(
        @{ f = "index.html";        n = "Entrada" },
        @{ f = "informe.html";      n = "Informe" },
        @{ f = "antecedentes.html"; n = "Antecedentes" },
        @{ f = "cronologia.html";   n = "Cronología" },
        @{ f = "dimensiones.html";  n = "Dimensiones" },
        @{ f = "fuentes.html";      n = "Fuentes" }
    )
    foreach ($p in $paginas) {
        if ($p.f -eq $archivo) { $nav += '<a href="' + $p.f + '" aria-current="page">' + $p.n + '</a>' + "`n        " }
        else                   { $nav += '<a href="' + $p.f + '">' + $p.n + '</a>' + "`n        " }
    }

    $extra = ""
    if ($archivo -eq "cronologia.html") { $extra = '  <script src="cronologia.js" defer></script>' + "`n" }

    $doc = @"
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$titulo</title>
  <meta name="description" content="$descripcion">
  <meta name="robots" content="noindex, nofollow">
  <meta property="og:title" content="$titulo">
  <meta property="og:description" content="$descripcion">
  <meta property="og:type" content="article">
  <meta property="og:url" content="$base$archivo">
  <meta property="og:locale" content="es_ES">
  <meta property="og:image" content="$base`imagenes/tarjeta.png">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:image" content="$base`imagenes/tarjeta.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Crimson+Pro:ital,wght@0,400;0,600;1,400;1,600&family=Space+Mono:wght@400;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="estilos.css">
$extra</head>
<body>

  <header class="barra">
    <div class="barra-interna">
      <a class="marca" href="index.html">Panamá 2023</a>
      <nav>
        $nav</nav>
    </div>
  </header>

  <div class="envoltorio">

    <div class="encabezado">
      <div class="ficha">$ficha</div>
      <h1>$h1</h1>
      <p class="bajada">$bajada</p>
    </div>

$cuerpo

$paso

    <footer>
      Informe de investigación · Alonso Marañón Tovar<br>
      Fondecyt Regular 1240777 — «Revueltas urbanas en América Latina (1989-2023): determinantes, tipos, dinámicas y consecuencias»<br>
      Documento de trabajo del proyecto. Circulación interna.
    </footer>

  </div>

</body>
</html>
"@
    $ruta = Join-Path $Destino $archivo
    [System.IO.File]::WriteAllText($ruta, $doc, (New-Object System.Text.UTF8Encoding($false)))
    Write-Output ("escrito: " + $archivo)
}

# ---------- paso entre paginas ----------
function Paso($anterior, $nombreAnt, $siguiente, $nombreSig) {
    $izq = ""
    $der = ""
    if ($anterior  -ne "") { $izq = '<a href="' + $anterior  + '">← ' + $nombreAnt + '</a>' }
    if ($siguiente -ne "") { $der = '<a href="' + $siguiente + '">' + $nombreSig + ' →</a>' }
    return '    <div class="paso"><span>' + $izq + '</span><span>' + $der + '</span></div>'
}

# ---------- 1. antecedentes ----------
$r1 = Render $tramoS1
Pagina "antecedentes.html" `
  "Antecedentes estructurales · Panamá 2023" `
  "Sección 1 del informe: condiciones socioeconómicas, políticas, étnicas y organizativas previas a la revuelta urbana de Panamá en 2023." `
  '<span>Sección <b>1</b></span><span>Preguntas <b>1.1 — 1.5</b></span><span>Contexto <b>mediano y largo plazo</b></span>' `
  "Antecedentes estructurales" `
  "Qué había en Panamá antes del 19 de octubre: el modelo económico dual, el sistema de partidos en descomposición y treinta años de conflicto minero." `
  ((IndicePreguntas $r1.preguntas "Las cinco preguntas de esta sección") + $r1.html) `
  (Paso "informe.html" "Portada del informe" "cronologia.html" "Narrativa cronológica")

# ---------- 2. cronologia ----------
$r2 = Render $tramoS2
$cuerpo2 = @"
    <div class="buscador">
      <label for="q">Buscar en los 45 días</label>
      <input type="search" id="q" placeholder="Suntracs, Corte Suprema, toque de queda…" autocomplete="off">
      <div class="resultado" id="resultado"></div>
    </div>

    <div class="con-riel">
      <div class="cronologia-cuerpo">
$($r2.html)
      </div>
      <aside class="riel">
        <div class="riel-titulo">45 días</div>
$($r2.riel)      </aside>
    </div>
"@
Pagina "cronologia.html" `
  "Narrativa cronológica · Panamá 2023" `
  "Sección 2 del informe: la revuelta día por día, del 19 de octubre al 2 de diciembre de 2023, y sus consecuencias." `
  '<span>Sección <b>2</b></span><span>Del <b>19 oct</b> al <b>2 dic</b></span><span>Días <b>43</b></span><span>Semanas <b>7</b></span>' `
  "Narrativa cronológica" `
  "De la promulgación de la Ley 406 al fallo de la Corte Suprema: cuarenta y cinco días, día por día." `
  $cuerpo2 `
  (Paso "antecedentes.html" "Antecedentes" "dimensiones.html" "Síntesis por dimensiones")

# ---------- 3. dimensiones ----------
$r3 = Render $tramoS3
Pagina "dimensiones.html" `
  "Síntesis e interpretación por dimensiones · Panamá 2023" `
  "Sección 3 del informe: alcance, organizaciones, demandas, tácticas, represión, víctimas, opinión pública y actores internacionales." `
  '<span>Sección <b>3</b></span><span>Preguntas <b>3.1 — 3.19</b></span><span>Mirada <b>transversal</b></span>' `
  "Síntesis e interpretación por dimensiones" `
  "Diecinueve preguntas sobre la revuelta considerada en conjunto, más allá de la cronología." `
  ((IndicePreguntas $r3.preguntas "Las diecinueve dimensiones") + $r3.html) `
  (Paso "cronologia.html" "Cronología" "fuentes.html" "Bibliografía y fuentes")

# ---------- 4. fuentes ----------
$sbB = New-Object System.Text.StringBuilder
[void]$sbB.AppendLine('    <div class="bibliografia">')
foreach ($it in $tramoBi) {
    $entrada = $it.html
    # Mendeley deja las URLs como texto plano: las convierto en enlaces
    # para que se pueda ir a la fuente con un clic. Si la entrada ya trae
    # un enlace propio del Word, la dejo como está.
    if ($entrada -notmatch "<a ") {
        $entrada = [regex]::Replace($entrada, "(https?://[^\s<]+[^\s<\.,;)])", '<a href="$1" rel="noopener" target="_blank">$1</a>')
    }
    [void]$sbB.AppendLine('      <p>' + $entrada + '</p>')
}
[void]$sbB.AppendLine('    </div>')
Pagina "fuentes.html" `
  "Bibliografía y fuentes · Panamá 2023" `
  "Referencias en formato APA utilizadas en el informe sobre la revuelta urbana de Panamá 2023." `
  ('<span>Referencias <b>' + $tramoBi.Count + '</b></span><span>Formato <b>APA</b></span>') `
  "Bibliografía y fuentes" `
  "Todo lo que se leyó para escribir este informe: academia, prensa, informes institucionales y material audiovisual." `
  $sbB.ToString() `
  (Paso "dimensiones.html" "Dimensiones" "" "")

Write-Output "listo"
