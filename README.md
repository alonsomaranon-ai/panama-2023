# Informe sobre la revuelta urbana en Panamá, 2023

Versión web del informe de investigación sobre la revuelta panameña de octubre-diciembre de 2023 contra el contrato minero de la Ley 406.

**Autor:** Alonso Marañón Tovar
**Proyecto:** Fondecyt Regular 1240777 — «Revueltas urbanas en América Latina (1989-2023): determinantes, tipos, dinámicas y consecuencias»
**Versión:** final, junio de 2025
**Extensión:** 33.477 palabras · 20 gráficos · 164 referencias

---

## Por qué existe

El informe se entrega en Word, como pide el template del proyecto. Pero un documento de 33.000 palabras en `.docx` es difícil de consultar: no se puede enlazar una pregunta puntual, no se puede buscar dentro de la cronología, y en un celular es ilegible.

Esta versión web resuelve eso sin tocar una coma del texto:

- **Cada pregunta del template tiene su propia dirección.** El enlace `dimensiones.html#p3-12` abre directamente la pregunta 3.12 (víctimas). Sirve para discutir un punto por mail sin explicar en qué página está.
- **La cronología se puede interrogar.** Un buscador marca en qué días aparece un término —una organización, un lugar, una autoridad— y el índice lateral muestra la distribución en los 45 días. Ver *cuándo* entra un actor en escena es parte del análisis, no un adorno.
- **Se lee en celular y se imprime bien.**

---

## Dos capas

El sitio tiene una entrada de divulgación y un informe completo debajo.

**La entrada** (`index.html`) es un relato de unas 1.650 palabras para alguien que no sabe nada de Panamá: cuenta la revuelta como historia, sin numeración de preguntas, sin citas en el cuerpo y sin el andamiaje metodológico. Se lee en siete minutos.

**El informe** (`informe.html` y sus cuatro secciones) es el documento de investigación completo, sin resumir ni recortar: las 33.000 palabras, los 43 días, las 228 citas y las 164 fuentes.

No son dos versiones que puedan contradecirse: son una puerta y un archivo. Todo lo que afirma el relato está documentado abajo, y desde el relato se llega al informe en un clic. Esa es la parte que hace la divulgación defendible: quien dude de una cifra puede ir a buscarla.

---

## Cómo se navega

| Página | Contiene |
|---|---|
| `index.html` | **La entrada pública**: el relato de la revuelta |
| `informe.html` | Portada del informe, cifras principales, índice |
| `antecedentes.html` | Sección 1 · preguntas 1.1 a 1.5 · 11 gráficos |
| `cronologia.html` | Sección 2 · inicio, 7 semanas, 43 días, desenlace y consecuencias |
| `dimensiones.html` | Sección 3 · preguntas 3.1 a 3.19 · 8 gráficos |
| `fuentes.html` | Bibliografía en APA, 164 referencias con enlace |

---

## Qué hace cada archivo

```
panama-2023-web/
├── index.html          la entrada pública: el relato (escrita a mano)
├── informe.html        la portada del informe (escrita a mano)
├── antecedentes.html   \
├── cronologia.html      |  generadas automáticamente desde el .docx
├── dimensiones.html     |  no se editan a mano: se regeneran
├── fuentes.html        /
├── estilos.css         toda la apariencia del sitio, en un solo archivo
├── cronologia.js       el buscador y el índice lateral de fechas
├── imagenes/           los 20 gráficos extraídos del Word
└── herramientas/       los dos programas que convierten el Word en web
```

**`estilos.css`** es el único archivo que hay que tocar para cambiar cómo se ve algo. Arriba de todo están las variables: colores y tipografías con nombre. Cambiás `--cobre` en una línea y cambia el acento de las cinco páginas.

**`cronologia.js`** solo agrega comodidades. Si se borra, el informe sigue completo y legible: se pierden el buscador y el índice lateral, nada más.

---

## Cómo actualizarlo si corregís el Word

Los cuatro archivos de contenido salen del `.docx` mediante dos programas. Si el informe cambia, no se edita el HTML: se vuelve a generar.

**1.** Descomprimir el `.docx` (es un ZIP por dentro) en una carpeta:

```bash
unzip "Panamá 2023 - Alonso Marañon.docx" -d doc
```

**2.** Extraer el texto a un formato intermedio, una línea por párrafo:

```bash
powershell -File herramientas/extraer.ps1 -DocDir doc -Salida herramientas/intermedio.txt
```

**3.** Armar las páginas:

```bash
powershell -File herramientas/generar.ps1 -Intermedio herramientas/intermedio.txt -Destino .
```

`extraer.ps1` conserva cursivas, negritas, notas al pie, hipervínculos, los gráficos y —esto costó encontrarlo— las 228 citas de Mendeley, que el Word guarda como objetos especiales y que una lectura ingenua del archivo se saltea.

`generar.ps1` reconoce por su forma qué es cada párrafo: los `SECCIÓN` separan páginas, los `1.1` son preguntas, los `19 de Octubre` son días de la cronología, los `Fuente:` son epígrafes de gráfico.

Si agregás gráficos nuevos al Word, hay que copiarlos también:

```bash
cp doc/word/media/*.png imagenes/
```

---

## La tarjeta para compartir

`imagenes/tarjeta.png` es la imagen de 1200×630 que muestran WhatsApp, Twitter, LinkedIn y el correo cuando alguien pega el link. Se dibuja por programa, no a mano:

```bash
powershell -File herramientas/tarjeta.ps1 -Salida imagenes/tarjeta.png
```

Si cambiás el título o las cifras, se edita ese archivo y se vuelve a correr. Usa Georgia y Consolas, que vienen con Windows, porque las tipografías del sitio se cargan de internet y no están instaladas en la máquina.

Las etiquetas que apuntan a esa imagen (`og:image`, `twitter:card`) están en las seis páginas y usan direcciones absolutas: **si el sitio cambia de dirección, hay que actualizar la variable `$base` en `generar.ps1`** y las etiquetas escritas a mano en `index.html` e `informe.html`.

---

## Estética

Tipografías: **Crimson Pro** para el texto (serif, pensada para lectura larga) y **Space Mono** para fechas, códigos de pregunta y citas. Se cargan desde Google Fonts.

El acento es **cobre** (`#A65A2E`) y los enlaces visitados viran a **verdín** (`#4E7A63`): el color sale del metal en disputa y se oxida a medida que se lee. Es el único gesto decorativo del sitio, y quiere decir algo.

Las 228 citas van en tipografía mono, más chicas y en gris, para que se lean como aparato crítico y no interrumpan la prosa.

---

## Circulación

Documento de trabajo del proyecto Fondecyt. **Circulación interna.** Todas las páginas llevan `noindex` para que no las levanten los buscadores.

Los 20 gráficos pertenecen a sus autores originales (PNUD, IFRC, Díaz Pinzón & Almeida, entre otros) y se reproducen con crédito visible para uso académico.

El informe trata sobre hechos con víctimas fatales, personas heridas y responsabilidades policiales. Toda la información proviene de fuentes públicas citadas, pero la decisión de abrir el sitio al público corresponde al equipo del proyecto, no a una sola persona.
