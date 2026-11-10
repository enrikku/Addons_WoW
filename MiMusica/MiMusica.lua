-- MiMusica: reproductor de música propia para WoW (Forever / Classic)
local ADDON_NAME = ...
local RUTA = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Musica\\"
local FILAS = 10
local ALTO_FILA = 16

local canciones = MiMusica_Canciones or {}
local db

local actual = nil        -- índice de la canción actual
local handle = nil        -- handle del sonido que suena
local temporizador = nil  -- temporizador para pasar a la siguiente
local orden = {}          -- orden de reproducción (normal o aleatorio)
local posOrden = 0
local musicaJuegoPrevia = nil

local visibles = {}       -- índices filtrados por la búsqueda
local offset = 0

local Actualizar, ActualizarLista, Siguiente

---------------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------------
local function Mensaje(txt)
    print("|cff33ccff[MiMusica]|r " .. txt)
end

local function Formato(seg)
    if not seg or seg <= 0 then return "" end
    return string.format("%d:%02d", math.floor(seg / 60), math.floor(seg % 60))
end

local function Nombre(c)
    if not c then return "" end
    return c.titulo or (c.archivo:gsub("%.%w+$", ""))
end

local function ConstruirOrden()
    wipe(orden)
    for i = 1, #canciones do orden[i] = i end
    if db.aleatorio then
        for i = #orden, 2, -1 do
            local j = math.random(i)
            orden[i], orden[j] = orden[j], orden[i]
        end
    end
    posOrden = 0
    if actual then
        for k, v in ipairs(orden) do
            if v == actual then posOrden = k break end
        end
    end
end

local function CancelarTemporizador()
    if temporizador then
        temporizador:Cancel()
        temporizador = nil
    end
end

local function SilenciarMusicaJuego()
    if db.silenciarJuego and db.canal ~= "Music" and musicaJuegoPrevia == nil then
        musicaJuegoPrevia = GetCVar("Sound_EnableMusic")
        SetCVar("Sound_EnableMusic", "0")
    end
end

local function RestaurarMusicaJuego()
    if musicaJuegoPrevia ~= nil then
        SetCVar("Sound_EnableMusic", musicaJuegoPrevia)
        musicaJuegoPrevia = nil
    end
end

---------------------------------------------------------------------------
-- Reproducción
---------------------------------------------------------------------------
local function Parar(restaurar)
    CancelarTemporizador()
    if handle then
        StopSound(handle)
        handle = nil
    end
    if restaurar ~= false then RestaurarMusicaJuego() end
    Actualizar()
end

local function Reproducir(i)
    local c = canciones[i]
    if not c then return end
    Parar(false)
    SilenciarMusicaJuego()

    local ok, h = PlaySoundFile(RUTA .. c.archivo, db.canal)
    actual = i
    db.ultima = i
    for k, v in ipairs(orden) do
        if v == i then posOrden = k break end
    end

    if not ok then
        RestaurarMusicaJuego()
        Mensaje("No se pudo reproducir: " .. c.archivo ..
            ". ¿La añadiste con el juego abierto? Hay que cerrar el juego del todo y volver a entrar.")
        Actualizar()
        return
    end

    handle = h
    if c.duracion and c.duracion > 0 then
        temporizador = C_Timer.NewTimer(c.duracion + 1, function()
            temporizador = nil
            handle = nil
            Siguiente()
        end)
    end
    Actualizar()
end

function Siguiente()
    if #canciones == 0 then return end
    posOrden = posOrden + 1
    if posOrden > #orden then
        if db.aleatorio then ConstruirOrden() end
        posOrden = 1
    end
    Reproducir(orden[posOrden])
end

local function Anterior()
    if #canciones == 0 then return end
    posOrden = posOrden - 1
    if posOrden < 1 then posOrden = #orden end
    Reproducir(orden[posOrden])
end

local function PlayParar()
    if handle then
        Parar()
    elseif #canciones > 0 then
        Reproducir(actual or db.ultima or orden[1])
    end
end

---------------------------------------------------------------------------
-- Ventana
---------------------------------------------------------------------------
local f = CreateFrame("Frame", "MiMusicaFrame", UIParent, "BackdropTemplate")
f:SetSize(320, 330)
f:SetPoint("CENTER")
f:SetFrameStrata("MEDIUM")
f:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 24,
    insets = { left = 6, right = 6, top = 6, bottom = 6 },
})
f:SetMovable(true)
f:EnableMouse(true)
f:SetClampedToScreen(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    db.pos = { p, rp, x, y }
end)
f:SetScript("OnShow", function() if db then db.visible = true end end)
f:SetScript("OnHide", function() if db then db.visible = false end end)
f:Hide()
tinsert(UISpecialFrames, "MiMusicaFrame") -- se cierra con Esc

local titulo = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titulo:SetPoint("TOP", 0, -14)
titulo:SetText("MiMusica")

local cerrar = CreateFrame("Button", nil, f, "UIPanelCloseButton")
cerrar:SetPoint("TOPRIGHT", -4, -4)

local sonando = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
sonando:SetPoint("TOPLEFT", 16, -38)
sonando:SetPoint("TOPRIGHT", -16, -38)
sonando:SetJustifyH("CENTER")
sonando:SetWordWrap(false)

local function Boton(texto, ancho, x, accion)
    local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    b:SetSize(ancho, 22)
    b:SetPoint("TOP", x, -58)
    b:SetText(texto)
    b:SetScript("OnClick", accion)
    return b
end
Boton("<<", 50, -75, Anterior)
local botonPlay = Boton("Play", 80, 0, PlayParar)
Boton(">>", 50, 75, Siguiente)

local function Casilla(texto, x, y, clave, alCambiar)
    local c = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    c:SetSize(24, 24)
    c:SetPoint("TOPLEFT", x, y)
    local t = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t:SetPoint("LEFT", c, "RIGHT", 2, 0)
    t:SetText(texto)
    c:SetScript("OnClick", function(self)
        db[clave] = self:GetChecked() and true or false
        if alCambiar then alCambiar() end
    end)
    c.clave = clave
    return c
end
local casAleatorio = Casilla("Aleatorio", 14, -86, "aleatorio", ConstruirOrden)
local casSilenciar = Casilla("Silenciar música del juego", 120, -86, "silenciarJuego", function()
    if db.silenciarJuego and handle then SilenciarMusicaJuego() else RestaurarMusicaJuego() end
end)

local buscar = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
buscar:SetSize(220, 20)
buscar:SetPoint("TOPLEFT", 80, -114)
buscar:SetAutoFocus(false)
buscar:SetScript("OnTextChanged", function() offset = 0; ActualizarLista() end)
buscar:SetScript("OnEscapePressed", buscar.ClearFocus)
buscar:SetScript("OnEnterPressed", buscar.ClearFocus)
local etqBuscar = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
etqBuscar:SetPoint("RIGHT", buscar, "LEFT", -8, 0)
etqBuscar:SetText("Buscar:")

local lista = CreateFrame("Frame", nil, f)
lista:SetPoint("TOPLEFT", 16, -142)
lista:SetPoint("TOPRIGHT", -16, -142)
lista:SetHeight(FILAS * ALTO_FILA)
lista:EnableMouseWheel(true)

local pie = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
pie:SetPoint("BOTTOM", 0, 16)

local filas = {}
for i = 1, FILAS do
    local b = CreateFrame("Button", nil, lista)
    b:SetHeight(ALTO_FILA)
    b:SetPoint("TOPLEFT", 0, -(i - 1) * ALTO_FILA)
    b:SetPoint("RIGHT")
    b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    b.nombre = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.nombre:SetPoint("LEFT", 2, 0)
    b.nombre:SetPoint("RIGHT", -40, 0)
    b.nombre:SetJustifyH("LEFT")
    b.nombre:SetWordWrap(false)
    b.dur = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    b.dur:SetPoint("RIGHT", -2, 0)
    b:SetScript("OnClick", function(self)
        if self.indice then Reproducir(self.indice) end
    end)
    filas[i] = b
end

lista:SetScript("OnMouseWheel", function(_, delta)
    offset = math.max(0, math.min(offset - delta * 3, math.max(0, #visibles - FILAS)))
    ActualizarLista()
end)

function ActualizarLista()
    wipe(visibles)
    local q = (buscar:GetText() or ""):lower()
    for i, c in ipairs(canciones) do
        if q == "" or Nombre(c):lower():find(q, 1, true) then
            visibles[#visibles + 1] = i
        end
    end
    offset = math.max(0, math.min(offset, math.max(0, #visibles - FILAS)))

    for r = 1, FILAS do
        local b = filas[r]
        local idx = visibles[offset + r]
        if idx then
            local c = canciones[idx]
            b.indice = idx
            if idx == actual then
                b.nombre:SetText("|cff33ccff" .. Nombre(c) .. "|r")
            else
                b.nombre:SetText(Nombre(c))
            end
            b.dur:SetText(Formato(c.duracion))
            b:Show()
        else
            b.indice = nil
            b:Hide()
        end
    end

    if #canciones == 0 then
        pie:SetText("No hay canciones. Ejecuta GenerarLista.bat")
    elseif #visibles == 0 then
        pie:SetText("Sin resultados")
    else
        pie:SetText(string.format("%d-%d de %d  ·  rueda del ratón para desplazar",
            offset + 1, math.min(offset + FILAS, #visibles), #visibles))
    end
end

function Actualizar()
    botonPlay:SetText(handle and "Parar" or "Play")
    if actual and canciones[actual] then
        local prefijo = handle and "Sonando: " or "En pausa: "
        sonando:SetText(prefijo .. "|cffffffff" .. Nombre(canciones[actual]) .. "|r")
    else
        sonando:SetText(#canciones > 0 and "Elige una canción" or "")
    end
    if f:IsShown() then ActualizarLista() end
end
f:HookScript("OnShow", function() Actualizar() end)

---------------------------------------------------------------------------
-- Comandos y atajos de teclado
---------------------------------------------------------------------------
function MiMusica_Ventana() f:SetShown(not f:IsShown()) end
MiMusica_PlayParar = PlayParar
MiMusica_Siguiente = function() Siguiente() end
MiMusica_Anterior = Anterior

BINDING_HEADER_MIMUSICA = "MiMusica"
BINDING_NAME_MIMUSICA_VENTANA = "Mostrar/ocultar ventana"
BINDING_NAME_MIMUSICA_PLAY = "Play / Parar"
BINDING_NAME_MIMUSICA_SIGUIENTE = "Siguiente canción"
BINDING_NAME_MIMUSICA_ANTERIOR = "Canción anterior"

local CANALES = { master = "Master", musica = "Music", music = "Music",
    efectos = "SFX", sfx = "SFX", ambiente = "Ambience", ambience = "Ambience",
    dialogo = "Dialog", dialog = "Dialog" }

SLASH_MIMUSICA1 = "/musica"
SLASH_MIMUSICA2 = "/mimusica"
SlashCmdList.MIMUSICA = function(msg)
    local cmd, arg = (msg or ""):lower():match("^(%S*)%s*(.-)$")
    if cmd == "" then
        MiMusica_Ventana()
    elseif cmd == "play" or cmd == "parar" or cmd == "stop" then
        PlayParar()
    elseif cmd == "sig" or cmd == "siguiente" or cmd == "next" then
        Siguiente()
    elseif cmd == "ant" or cmd == "anterior" or cmd == "prev" then
        Anterior()
    elseif cmd == "aleatorio" then
        db.aleatorio = not db.aleatorio
        casAleatorio:SetChecked(db.aleatorio)
        ConstruirOrden()
        Mensaje("Aleatorio: " .. (db.aleatorio and "activado" or "desactivado"))
    elseif cmd == "canal" then
        local c = CANALES[arg]
        if c then
            db.canal = c
            Mensaje("Canal de sonido: " .. c .. " (se aplica a la próxima canción)")
        else
            Mensaje("Canales: master, musica, efectos, ambiente, dialogo. Actual: " .. db.canal)
        end
    else
        Mensaje("Comandos: /musica (ventana), /musica play, /musica sig, /musica ant, " ..
            "/musica aleatorio, /musica canal <master|musica|efectos|ambiente|dialogo>")
    end
end

---------------------------------------------------------------------------
-- Inicio y cierre
---------------------------------------------------------------------------
local eventos = CreateFrame("Frame")
eventos:RegisterEvent("ADDON_LOADED")
eventos:RegisterEvent("PLAYER_LOGOUT")
eventos:SetScript("OnEvent", function(_, evento, nombre)
    if evento == "ADDON_LOADED" and nombre == ADDON_NAME then
        MiMusicaDB = MiMusicaDB or {}
        db = MiMusicaDB
        if db.aleatorio == nil then db.aleatorio = false end
        if db.silenciarJuego == nil then db.silenciarJuego = true end
        db.canal = db.canal or "Master"
        if db.ultima and not canciones[db.ultima] then db.ultima = nil end

        -- Por si se cerró el juego con la música del juego silenciada
        if db.musicaJuegoGuardada ~= nil then
            SetCVar("Sound_EnableMusic", db.musicaJuegoGuardada)
            db.musicaJuegoGuardada = nil
        end

        if db.pos then
            f:ClearAllPoints()
            f:SetPoint(db.pos[1], UIParent, db.pos[2], db.pos[3], db.pos[4])
        end
        casAleatorio:SetChecked(db.aleatorio)
        casSilenciar:SetChecked(db.silenciarJuego)
        ConstruirOrden()
        if db.visible then f:Show() end

        Mensaje(#canciones .. " canciones cargadas. Escribe /musica para abrir el reproductor.")
    elseif evento == "PLAYER_LOGOUT" and db then
        if musicaJuegoPrevia ~= nil then
            db.musicaJuegoGuardada = musicaJuegoPrevia
            SetCVar("Sound_EnableMusic", musicaJuegoPrevia)
        end
    end
end)
