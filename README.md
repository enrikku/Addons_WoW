# Addons WoW

Colección de addons sencillos para World of Warcraft (Retail y Classic).

| Addon | Qué hace | Comando |
|---|---|---|
| [MiFPS](#mifps) | Muestra los FPS y la latencia en pantalla | `/fps` |
| [MiMusica](#mimusica) | Reproductor de tu propia música dentro del juego | `/musica` |
| [MiRetrato](#miretrato) | Cambia el retrato de tu personaje junto a la barra de vida | `/retrato` |

## Instalación

1. Copia la carpeta de cada addon (`MiFPS`, `MiMusica`, `MiRetrato`) en
   `World of Warcraft\_retail_\Interface\AddOns\` (o `_classic_`, `_classic_era_`, según tu versión).
2. Si el juego estaba abierto, ciérralo del todo y vuelve a entrar.
3. Activa los addons en la pantalla de selección de personaje → **AddOns**.

> Los archivos nuevos (canciones, imágenes) solo se detectan al arrancar el juego: `/reload` no basta.

---

## MiFPS

Muestra un pequeño recuadro con los FPS y la latencia (ms), actualizado cada 0,25 s.

- **Colores FPS:** verde ≥ 60, amarillo ≥ 30, rojo por debajo.
- **Colores latencia:** verde < 100 ms, amarillo < 250 ms, rojo por encima. Se muestra la mayor entre latencia local y de mundo.
- **Arrastra** el recuadro con el botón izquierdo para moverlo (si no está bloqueado).
- **Pasa el ratón** por encima para ver el detalle: FPS con decimales, latencia local y latencia de mundo.

### Comandos

`/mifps` funciona igual que `/fps`.

| Comando | Qué hace |
|---|---|
| `/fps` o `/fps toggle` | Muestra u oculta el recuadro |
| `/fps lock` | Bloquea o desbloquea la posición (para no moverlo sin querer) |
| `/fps ms` | Muestra u oculta la latencia |
| `/fps escala <0.5-3>` | Cambia el tamaño. Ej.: `/fps escala 1.5` |
| `/fps reset` | Vuelve a la configuración inicial (posición arriba en el centro, escala 1, visible) |
| `/fps help` (o cualquier otra cosa) | Muestra la lista de comandos |

La configuración se guarda para toda la cuenta (`MiFPSDB`).

---

## MiMusica

Reproductor de música propia (`.mp3` u `.ogg`) con ventana, lista de canciones, búsqueda y modo aleatorio.

### Añadir canciones

1. Copia tus canciones en `MiMusica\Musica\`.
2. Ejecuta `MiMusica\GenerarLista.bat`. Crea `Canciones.lua` con la lista y la duración de cada canción.
3. Cierra el juego del todo y vuelve a entrar.

Avisos del script:
- **Canciones sin duración:** no pasan solas a la siguiente. Suele pasar con `.ogg`; convertirlas a `.mp3` lo soluciona.
- **Nombres con acentos o símbolos:** si alguna no suena, renómbrala sin acentos ni símbolos y vuelve a generar la lista.

### La ventana

- **`<<` / `Play`·`Parar` / `>>`:** canción anterior, reproducir o parar, canción siguiente.
- **Aleatorio:** mezcla el orden de reproducción.
- **Silenciar música del juego:** apaga la música de WoW mientras suena la tuya y la restaura al parar (activado por defecto; no se aplica si el canal es `musica`).
- **Buscar:** filtra la lista por nombre.
- **Lista:** haz clic en una canción para reproducirla; usa la rueda del ratón para desplazarte.
- Se mueve arrastrándola y se cierra con `Esc` o con la X. Recuerda su posición y si estaba abierta.

### Comandos

`/mimusica` funciona igual que `/musica`.

| Comando | Qué hace |
|---|---|
| `/musica` | Abre o cierra la ventana del reproductor |
| `/musica play` (o `parar`, `stop`) | Reproduce si está parado y para si está sonando |
| `/musica sig` (o `siguiente`, `next`) | Pasa a la siguiente canción |
| `/musica ant` (o `anterior`, `prev`) | Vuelve a la canción anterior |
| `/musica aleatorio` | Activa o desactiva el modo aleatorio |
| `/musica canal <canal>` | Elige por qué canal de sonido suena (se aplica a la próxima canción). Canales: `master`, `musica`, `efectos`, `ambiente`, `dialogo`. Por defecto `master`. Sin argumento muestra el actual |

El canal decide qué control de volumen del juego afecta a tu música (Opciones → Sonido).

### Atajos de teclado

En **Opciones → Atajos de teclado → AddOns → MiMusica** puedes asignar teclas a:
mostrar/ocultar ventana, Play/Parar, siguiente canción y canción anterior.

La configuración se guarda para toda la cuenta (`MiMusicaDB`).

---

## MiRetrato

Sustituye el retrato de tu personaje (la cara redonda junto a la barra de vida) por un icono del juego, el icono de tu clase o una foto tuya. Se vuelve a aplicar solo cuando el juego intenta poner el retrato original (cambiar de zona, montarte, etc.).

### La ventana (`/retrato`)

- **Rejilla de iconos:** 16 iconos predefinidos; clic para usar uno.
- **Caja "Imagen, icono o ID de hechizo":** escribe un valor (ver `/retrato icono` abajo) y pulsa Enter u **OK**.
- **Icono de clase:** usa el icono redondo de tu clase.
- **Original:** vuelve al retrato normal.

### Comandos

`/miretrato` funciona igual que `/retrato`.

| Comando | Qué hace |
|---|---|
| `/retrato` | Abre o cierra la ventana |
| `/retrato imagen <nombre>` | Usa una imagen propia de `MiRetrato\Imagenes\<nombre>.tga`. Ej.: `/retrato imagen gato` |
| `/retrato icono <valor>` | Usa un icono. `<valor>` puede ser: un **ID de hechizo** (usa su icono) o un fileID de textura, p. ej. `133` · un **nombre de icono** que empiece por `INV_`, `Spell_`, `Ability_` o `Achievement_`, p. ej. `INV_Sword_04` · una **ruta completa**, p. ej. `Interface\Icons\Spell_Fire_FlameBolt` |
| `/retrato clase` | Usa el icono de tu clase |
| `/retrato quitar` (o `original`, `reset`) | Vuelve al retrato normal |
| `/retrato help` (o cualquier otra cosa) | Muestra la lista de comandos |

La elección se guarda **por personaje** (`MiRetratoDB`).

### Usar una foto propia

1. Copia la foto (`.png`, `.jpg`, `.bmp`, `.gif`, `.tif`) en `MiRetrato\Imagenes\`.
2. Ejecuta `MiRetrato\ConvertirImagen.bat` (convierte todas las fotos de la carpeta) o **arrastra** una o varias fotos encima del `.bat`.
   El script recorta la foto en cuadrado desde el centro, la reduce a 256×256 y guarda un `.tga` en `Imagenes\` (los espacios y símbolos del nombre se cambian por `_`).
3. Si la imagen es nueva, reinicia el juego.
4. En el juego: `/retrato imagen <nombre>` (el script te muestra el comando exacto).

---

## Scripts auxiliares (Windows)

| Script | Para qué |
|---|---|
| `MiMusica\GenerarLista.bat` | Regenera `MiMusica\Canciones.lua` a partir de la carpeta `Musica` (ejecútalo cada vez que añadas o quites canciones) |
| `MiRetrato\ConvertirImagen.bat` | Convierte fotos a `.tga` 256×256 listas para usar como retrato |

Ambos `.bat` lanzan el `.ps1` del mismo nombre con PowerShell; no necesitan instalar nada.
